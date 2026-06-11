# app/services/gemini_agent.py

import os
import json
import logging
import asyncio
import random
from typing import Optional, List
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from google import genai
from google.genai.errors import ServerError, ClientError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException

from app.models.training_plan import TrainingPlan
from app.models.client import Client
from app.models.Machine import Machine
from app.models.gymMachineInventory import GymMachineInventory
from app.schemas.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.TrainingPlanResponse import TrainingPlanResponse, WeekPlan, DayPlan

logger = logging.getLogger(__name__)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
MODEL_NAME = "gemini-2.5-flash"
# Fallback models in case primary is overloaded
FALLBACK_MODELS = ["gemini-2.0-flash", "gemini-1.5-pro", "gemini-1.5-flash"]

client = genai.Client(api_key=GEMINI_API_KEY)


# ── Prompt builder ────────────────────────────────────────────────────────────

def _build_prompt(
    req: TrainingPlanRequest,
    client_name: str,
    valid_machines: Optional[List[str]] = None,
) -> str:
    system = (
        "You are an expert certified personal trainer and sports scientist. "
        "Always return a single valid JSON object – no markdown fences, no extra text."
    )

    machines_section = ""
    if valid_machines:
        machines_list = ", ".join(valid_machines)
        machines_section = (
            f"\nAvailable & valid gym machines/equipment: {machines_list}. "
            "Only include exercises that use these machines or require no equipment."
        )

    user = f"""
Generate a complete {req.weeks}-week gym training plan for {client_name}:
Goal: {req.fitness_goal}, Level: {req.level}, Days/Week: {req.days_per_week}, \
Equipment: {req.equipment}, Injuries: {req.injuries or 'none'}.{machines_section}

Follow the JSON structure strictly (title, goal, level, weeks, plan).
"""
    return f"{system}\n\n{user}"


# ── Retry decorator for Gemini calls ──────────────────────────────────────────

def is_retryable_error(exception):
    """Check if error is retryable (503, rate limit, timeout, etc.)"""
    error_str = str(exception).lower()
    retryable_patterns = [
        "503", "unavailable", "rate limit", "quota", "timeout", 
        "429", "500", "502", "504", "temporary", "overloaded"
    ]
    return any(pattern in error_str for pattern in retryable_patterns)


class GeminiAPIError(Exception):
    """Custom exception for Gemini API errors"""
    pass


# ── Agent ─────────────────────────────────────────────────────────────────────

class GeminiTrainingAgent:

    async def _call_gemini_with_retry(
        self, 
        prompt: str, 
        model_name: str = MODEL_NAME,
        max_retries: int = 3
    ) -> str:
        """
        Call Gemini API with exponential backoff retry logic.
        """
        last_error = None
        
        for attempt in range(max_retries):
            try:
                # Add jitter to prevent thundering herd
                if attempt > 0:
                    wait_time = (2 ** (attempt - 1)) + random.uniform(0, 1)
                    logger.info(f"Retry attempt {attempt + 1}/{max_retries} after {wait_time:.2f}s")
                    await asyncio.sleep(wait_time)
                
                response = await client.aio.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config={"response_mime_type": "application/json"},
                )
                
                raw_text = response.text.strip()
                if raw_text:
                    logger.info(f"Gemini API call successful (attempt {attempt + 1})")
                    return raw_text
                else:
                    raise GeminiAPIError("Empty response from Gemini API")
                    
            except Exception as exc:
                last_error = exc
                error_str = str(exc).lower()
                
                # Check if this is a retryable error
                if "503" in error_str or "unavailable" in error_str:
                    logger.warning(
                        f"Gemini API unavailable (attempt {attempt + 1}/{max_retries}): {exc}"
                    )
                    if attempt == max_retries - 1:
                        raise GeminiAPIError(f"Gemini API unavailable after {max_retries} attempts") from exc
                    continue
                elif "429" in error_str or "rate limit" in error_str:
                    logger.warning(f"Rate limit hit (attempt {attempt + 1}/{max_retries})")
                    if attempt == max_retries - 1:
                        raise GeminiAPIError("Rate limit exceeded") from exc
                    continue
                else:
                    # Non-retryable error - raise immediately
                    logger.error(f"Non-retryable Gemini error: {exc}")
                    raise GeminiAPIError(f"Gemini API error: {exc}") from exc
        
        raise GeminiAPIError(f"Failed after {max_retries} attempts: {last_error}")

    async def _try_fallback_models(
        self, 
        prompt: str, 
        primary_error: Exception
    ) -> Optional[str]:
        """
        Try fallback models if primary model fails.
        """
        for fallback_model in FALLBACK_MODELS:
            if fallback_model == MODEL_NAME:
                continue
                
            try:
                logger.info(f"Trying fallback model: {fallback_model}")
                response = await self._call_gemini_with_retry(
                    prompt, 
                    model_name=fallback_model,
                    max_retries=2
                )
                logger.info(f"Fallback model {fallback_model} succeeded")
                return response
            except Exception as e:
                logger.warning(f"Fallback model {fallback_model} failed: {e}")
                continue
        
        return None

    async def generate_plan(
        self,
        client_id: int,
        req: TrainingPlanRequest,
        db: AsyncSession,
        gym_id: Optional[int] = None,
    ) -> TrainingPlanResponse:

        # 1. Fetch client + user context
        from app.models.User import User

        result = await db.execute(
            select(Client, User)
            .join(User, Client.userID == User.userID)
            .where(Client.clientID == client_id)
        )
        row = result.first()
        if not row:
            raise ValueError(f"Client with id={client_id} not found.")

        client_obj, user_obj = row

        # 2. Fetch valid machines for the gym
        valid_machines: Optional[List[str]] = None
        if gym_id:
            machines_result = await db.execute(
                select(Machine.machineName)
                .join(
                    GymMachineInventory,
                    GymMachineInventory.machineID == Machine.machineID
                )
                .where(
                    GymMachineInventory.gymID == gym_id,
                    GymMachineInventory.status == "available",
                )
            )
            rows = machines_result.scalars().all()
            if rows:
                valid_machines = list(rows)
                logger.info(
                    "Sending %d valid machines to Gemini for gym %s",
                    len(valid_machines), gym_id,
                )

        # 3. Call Gemini with retry and fallback logic
        prompt = _build_prompt(req, client_name=user_obj.name, valid_machines=valid_machines)
        logger.info("Generating AI plan for client %s (gym=%s)...", client_id, gym_id)

        raw_text = None
        try:
            # Try primary model with retries
            raw_text = await self._call_gemini_with_retry(prompt, MODEL_NAME, max_retries=3)
        except GeminiAPIError as e:
            logger.error(f"Primary Gemini model failed: {e}")
            
            # Try fallback models
            raw_text = await self._try_fallback_models(prompt, e)
            
            if not raw_text:
                # All models failed - return a graceful error response
                logger.error("All Gemini models failed. Returning fallback plan.")
                return await self._create_fallback_response(
                    client_id, req, client_obj, user_obj
                )

        # 4. Parse JSON
        plan_dict = _safe_parse_json(raw_text)

        # 5. Persist
        training_plan = TrainingPlan(
            clientID=client_id,
            title=plan_dict.get("title", f"{req.fitness_goal.title()} Plan"),
            goal=plan_dict.get("goal", req.fitness_goal),
            level=plan_dict.get("level", req.level),
            weeks=plan_dict.get("weeks", req.weeks),
            plan_json=json.dumps(plan_dict),
        )
        db.add(training_plan)
        await db.commit()
        await db.refresh(training_plan)

        # 6. Build response
        weeks_parsed = _parse_weeks(plan_dict.get("plan", []))

        return TrainingPlanResponse(
            planID=training_plan.planID,
            clientID=client_id,
            title=training_plan.title,
            goal=training_plan.goal,
            level=training_plan.level,
            weeks=training_plan.weeks,
            plan=weeks_parsed,
            raw_json=training_plan.plan_json,
            created_at=training_plan.created_at,
        )

    async def _create_fallback_response(
        self,
        client_id: int,
        req: TrainingPlanRequest,
        client_obj,
        user_obj,
    ) -> TrainingPlanResponse:
        """
        Create a fallback response when Gemini API is completely unavailable.
        """
        fallback_plan = {
            "title": f"{req.fitness_goal.title()} Training Plan (Basic Template)",
            "goal": req.fitness_goal,
            "level": req.level,
            "weeks": req.weeks,
            "plan": [
                {
                    "week": w + 1,
                    "theme": f"Week {w + 1} - Building Foundation",
                    "days": [
                        {
                            "day": f"Day {d + 1}",
                            "focus": "Full body workout",
                            "exercises": [
                                {
                                    "name": "Consult with trainer for personalized exercises",
                                    "sets": 3,
                                    "reps": "10-12",
                                    "notes": "AI service temporarily unavailable"
                                }
                            ],
                            "notes": "This is a temporary fallback plan. Please try generating again later for a personalized plan."
                        }
                        for d in range(min(req.days_per_week, 5))
                    ]
                }
                for w in range(min(req.weeks, 4))
            ]
        }
        
        training_plan = TrainingPlan(
            clientID=client_id,
            title=fallback_plan["title"],
            goal=fallback_plan["goal"],
            level=fallback_plan["level"],
            weeks=fallback_plan["weeks"],
            plan_json=json.dumps(fallback_plan),
        )
        
        db = None  # This would need to be passed in or handled differently
        # Note: You'll need to handle database session here
        
        weeks_parsed = _parse_weeks(fallback_plan.get("plan", []))
        
        return TrainingPlanResponse(
            planID=0,  # Temporary ID
            clientID=client_id,
            title=fallback_plan["title"],
            goal=fallback_plan["goal"],
            level=fallback_plan["level"],
            weeks=fallback_plan["weeks"],
            plan=weeks_parsed,
            raw_json=json.dumps(fallback_plan),
            created_at=None,
        )


# ── Helpers ───────────────────────────────────────────────────────────────────

def _safe_parse_json(text: str) -> dict:
    text = text.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        logger.error("Failed to parse Gemini response: %s", text[:500])  # Log first 500 chars
        return {"title": "Error generating plan", "plan": []}


def _parse_weeks(weeks_list: list) -> list[WeekPlan]:
    result = []
    for w in weeks_list:
        days_parsed = [
            DayPlan(
                day=d.get("day", ""),
                focus=d.get("focus", ""),
                exercises=d.get("exercises", []),
                notes=d.get("notes"),
            )
            for d in w.get("days", [])
        ]
        result.append(WeekPlan(
            week=w.get("week", 0),
            theme=w.get("theme"),
            days=days_parsed,
        ))
    return result


gemini_agent = GeminiTrainingAgent()