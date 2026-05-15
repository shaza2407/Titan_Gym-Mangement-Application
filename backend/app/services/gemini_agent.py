# app/services/gemini_agent.py
"""
     Replaced with the actual models you have:
       - Machine          (app/models/Machine.py)
       - GymMachineInventory (app/models/gymMachineInventory.py)

     Now generates plans using machines that are "available" in a specific gym.
"""

import os
import json
import logging
from typing import Optional, List

from google import genai
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.training_plan import TrainingPlan
from app.models.client import Client
from app.models.Machine import Machine
from app.models.gymMachineInventory import GymMachineInventory
from app.schemas.TraingPlanRequest import TrainingPlanRequest
from app.schemas.TraingPlanResponse import TrainingPlanResponse, WeekPlan, DayPlan

logger = logging.getLogger(__name__)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
MODEL_NAME     = "gemini-2.5-flash"

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


# ── Agent ─────────────────────────────────────────────────────────────────────

class GeminiTrainingAgent:

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

        # 2. Fetch valid machines for the gym using your EXISTING models ✅
        valid_machines: Optional[List[str]] = None
        if gym_id:
            machines_result = await db.execute(
                select(Machine.machineName)
                .join(
                    GymMachineInventory,
                    GymMachineInventory.machineID == Machine.machineID
                )
                .where(
                    GymMachineInventory.gymID  == gym_id,
                    GymMachineInventory.status == "available",   # only available machines
                )
            )
            rows = machines_result.scalars().all()
            if rows:
                valid_machines = list(rows)
                logger.info(
                    "Sending %d valid machines to Gemini for gym %s",
                    len(valid_machines), gym_id,
                )

        # 3. Call Gemini
        prompt = _build_prompt(req, client_name=user_obj.name, valid_machines=valid_machines)
        logger.info("Generating AI plan for client %s (gym=%s)...", client_id, gym_id)

        try:
            response = await client.aio.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
                config={"response_mime_type": "application/json"},
            )
            raw_text = response.text.strip()
        except Exception as exc:
            logger.error("Gemini API call failed: %s", exc)
            raise RuntimeError(f"Gemini API error: {exc}") from exc

        # 4. Parse JSON
        plan_dict = _safe_parse_json(raw_text)

        # 5. Persist
        training_plan = TrainingPlan(
            clientID  = client_id,
            title     = plan_dict.get("title",  f"{req.fitness_goal.title()} Plan"),
            goal      = plan_dict.get("goal",   req.fitness_goal),
            level     = plan_dict.get("level",  req.level),
            weeks     = plan_dict.get("weeks",  req.weeks),
            plan_json = json.dumps(plan_dict),
        )
        db.add(training_plan)
        await db.commit()
        await db.refresh(training_plan)

        # 6. Build response
        weeks_parsed = _parse_weeks(plan_dict.get("plan", []))

        return TrainingPlanResponse(
            planID     = training_plan.planID,
            clientID   = client_id,
            title      = training_plan.title,
            goal       = training_plan.goal,
            level      = training_plan.level,
            weeks      = training_plan.weeks,
            plan       = weeks_parsed,
            raw_json   = training_plan.plan_json,
            created_at = training_plan.created_at,
        )


# ── Helpers ───────────────────────────────────────────────────────────────────

def _safe_parse_json(text: str) -> dict:
    text = text.replace("```json", "").replace("```", "").strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        logger.error("Failed to parse Gemini response: %s", text)
        return {"title": "Error generating plan", "plan": []}


def _parse_weeks(weeks_list: list) -> list[WeekPlan]:
    result = []
    for w in weeks_list:
        days_parsed = [
            DayPlan(
                day       = d.get("day", ""),
                focus     = d.get("focus", ""),
                exercises = d.get("exercises", []),
                notes     = d.get("notes"),
            )
            for d in w.get("days", [])
        ]
        result.append(WeekPlan(
            week  = w.get("week", 0),
            theme = w.get("theme"),
            days  = days_parsed,
        ))
    return result


gemini_agent = GeminiTrainingAgent()