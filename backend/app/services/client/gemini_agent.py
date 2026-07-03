# app/services/gemini_agent.py

import os
import json
import logging
import asyncio
import random
from typing import Optional, List

from google import genai
from google.genai.errors import ServerError, ClientError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException

from app.models.training_plan import TrainingPlan
from app.models.client import Client
from app.models.gymMachineInventory import GymMachineInventory
from app.schemas.client.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.client.TrainingPlanResponse import TrainingPlanResponse, WeekPlan, DayPlan

logger = logging.getLogger(__name__)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
MODEL_NAME = "gemini-3.5-flash"
FALLBACK_MODELS = ["gemini-2.5-flash", MODEL_NAME]

client = genai.Client(api_key=GEMINI_API_KEY)


# ── Prompt builder ────────────────────────────────────────────────────────────

def _build_prompt(
    req: TrainingPlanRequest,
    client_name: str,
    valid_machines: Optional[List[str]] = None,
    parent_plan: Optional[TrainingPlan] = None,
) -> str:
    system = (
        "You are an expert certified personal trainer and sports scientist. "
        "Return only a single valid JSON object – no markdown fences, no extra text, "
        "and keep it as small as possible."
    )

    machines_section = ""
    if valid_machines:
        machines_list = ", ".join(valid_machines)
        machines_section = (
            f"\nHARD CONSTRAINT – every exercise MUST use one of these machines: {machines_list}. "
            "If no machine fits, use a bodyweight alternative. "
            "Do NOT invent any other equipment."
        )
    else:
        machines_section = (
            "\nHARD CONSTRAINT – no gym machines available. "
            "Every single exercise MUST be bodyweight only. "
            "Do NOT use any equipment whatsoever."
        )

    user = f"Create a {req.weeks}-week plan for {client_name}. "
    user += f"Goal: {req.fitness_goal}. Level: {req.level}. "
    user += f"Days/week: {req.days_per_week}. "
    if req.equipment:
        user += f"Equipment: {req.equipment}. "
    if req.injuries:
        user += f"Injuries: {req.injuries}. "
    user += machines_section

    if parent_plan is not None:
        parent_data = json.loads(parent_plan.plan_json) if parent_plan.plan_json else {}
        user += (
            f"\n\nEDITING EXISTING PLAN: This is a revision of plan '{parent_plan.title}'. "
            "Use the previous plan as a base reference, keeping structure and duration "
            "(inject new exercises, adjust intensities, and add progression). "
            f"Previous plan summary: {json.dumps(parent_data, indent=2)[:3000]}"
        )

    # --- UPDATED STRICT JSON SCHEMA SECTION ---
    user += (
        "\n\nCRITICAL JSON INSTRUCTIONS: "
        "You must respond ONLY with a raw JSON object. Do not include markdown formatting or extra text. "
        "Use this exact schema:\n"
        "{\n"
        '  "title": "String",\n'
        '  "goal": "String",\n'
        '  "level": "String",\n'
        '  "weeks": 1,\n'
        '  "plan": [\n'
        '    {\n'
        '      "week": 1,\n'
        '      "theme": "String",\n'
        '      "days": [\n'
        '        {\n'
        '          "day": 1,\n'
        '          "focus": "String",\n'
        '          "exercises": [\n'
        '            {"name": "String (Machine or Bodyweight only)", "sets": 3, "reps": "10-12"}\n'
        '          ]\n'
        '        }\n'
        '      ]\n'
        '    }\n'
        '  ]\n'
        "}"
    )

    return f"{system}\n\n{user}"

# ── Retry decorator for Gemini calls ──────────────────────────────────────────

def is_retryable_error(exception: Exception) -> bool:
    text = str(exception).lower()
    return any(
        token in text
        for token in (
            "503", "unavailable", "rate limit", "quota",
            "429", "500", "502", "504", "temporary", "overloaded",
        )
    )


class GeminiAPIError(Exception):
    pass


# ── Agent ─────────────────────────────────────────────────────────────────────

class GeminiTrainingAgent:

    async def _call_gemini_with_retry(
        self,
        prompt: str,
        model_name: str = MODEL_NAME,
        max_retries: int = 2,
    ) -> str:
        last_error: Optional[Exception] = None

        for attempt in range(max_retries):
            try:
                if attempt > 0:
                    wait_time = 3.0 + random.uniform(0, 2)
                    logger.info(
                        "Retry %s/%s for model=%s after %.1fs",
                        attempt + 1, max_retries, model_name, wait_time,
                    )
                    await asyncio.sleep(wait_time)
                else:
                    await asyncio.sleep(0.4)

                response = await client.aio.models.generate_content(
                    model=model_name,
                    contents=prompt,
                    config={
                        "response_mime_type": "application/json",
                        "temperature": 0.7,
                        "max_output_tokens": 16384,
                    },
                )

                raw_text = response.text.strip()
                if raw_text:
                    logger.info(
                        "Gemini OK model=%s attempt=%s", model_name, attempt + 1
                    )
                    return raw_text
                raise GeminiAPIError("Empty response from Gemini API")

            except Exception as exc:
                last_error = exc
                if not is_retryable_error(exc):
                    logger.error("Non-retryable Gemini error: %s", exc)
                    raise GeminiAPIError(f"Gemini API error: {exc}") from exc

                logger.warning(
                    "Gemini retryable error model=%s attempt=%s/%s: %s",
                    model_name, attempt + 1, max_retries, exc,
                )

        raise GeminiAPIError(
            f"Failed after {max_retries} attempts for model={model_name}: {last_error}"
        )

    async def _try_fallback_models(
        self,
        prompt: str,
    ) -> Optional[str]:
        for model in FALLBACK_MODELS:
            if model == MODEL_NAME:
                continue
            try:
                logger.info("Trying fallback model: %s", model)
                text = await self._call_gemini_with_retry(prompt, model, max_retries=2)
                logger.info("Fallback model %s succeeded", model)
                return text
            except GeminiAPIError as exc:
                logger.warning("Fallback model %s failed: %s", model, exc)
                continue
        return None

    async def generate_plan(
        self,
        client_id: int,
        req: TrainingPlanRequest,
        db: AsyncSession,
        gym_id: Optional[int] = None,
        parent_plan: Optional[TrainingPlan] = None,
    ) -> TrainingPlanResponse:
        from app.models.User import User

        client_user = (
            await db.execute(
                select(Client, User)
                .join(User, Client.userID == User.userID)
                .where(Client.clientID == client_id)
            )
        ).first()
        if not client_user:
            raise ValueError(f"Client with id={client_id} not found.")
        client_obj, user_obj = client_user

        valid_machines: Optional[List[str]] = None
        if gym_id:
            machines = (
                await db.execute(
                    select(GymMachineInventory.machineName)
                    .where(GymMachineInventory.gymID == gym_id)
                )
            ).scalars().all()
            if machines:
                valid_machines = list(machines)
                logger.info("Gym %s machines sent to Gemini: %s", gym_id, valid_machines)

        prompt = _build_prompt(
            req, client_name=user_obj.name, valid_machines=valid_machines, parent_plan=parent_plan
        )
        logger.info("Generating plan client=%s gym=%s model=%s", client_id, gym_id, MODEL_NAME)

        raw_text: Optional[str] = None
        try:
            raw_text = await self._call_gemini_with_retry(prompt, MODEL_NAME, max_retries=2)
        except GeminiAPIError as exc:
            logger.error("Primary model failed: %s", exc)
            raw_text = await self._try_fallback_models(prompt)
            if not raw_text:
                logger.error("All models failed")
                raise RuntimeError("Server is busy. Please try again later.")

        plan_dict = _safe_parse_json(raw_text)
        if not plan_dict.get("plan"):
            logger.warning("Gemini JSON had no usable plan data")
            raise RuntimeError("Server is busy. Please try again later.")

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

        return TrainingPlanResponse(
            planID=training_plan.planID,
            clientID=client_id,
            title=training_plan.title,
            goal=training_plan.goal,
            level=training_plan.level,
            weeks=training_plan.weeks,
            plan=_parse_weeks(plan_dict.get("plan", []), req.days_per_week),
            raw_json=training_plan.plan_json,
            created_at=training_plan.created_at,
        )

    async def _create_fallback_response(
        self,
        client_id: int,
        req: TrainingPlanRequest,
        client_obj,
        user_obj,
        db: AsyncSession,
    ) -> TrainingPlanResponse:
        fallback = {
            "title": f"{req.fitness_goal.title()} Plan (Basic Template)",
            "goal": req.fitness_goal,
            "level": req.level,
            "weeks": req.weeks,
            "plan": [
                {
                    "week": w + 1,
                    "theme": f"Week {w + 1}",
                    "days": [
                        {
                            "day": f"Day {d + 1}",
                            "focus": "Full body",
                            "exercises": [
                                {
                                    "name": "Ask your trainer for a personalized workout",
                                    "sets": 3,
                                    "reps": "10-12",
                                    "notes": "AI unavailable – try again later",
                                }
                            ],
                            "notes": "Temporary fallback plan",
                        }
                        for d in range(min(req.days_per_week, 5))
                    ],
                }
                for w in range(min(req.weeks, 4))
            ],
        }

        plan = TrainingPlan(
            clientID=client_id,
            title=fallback["title"],
            goal=fallback["goal"],
            level=fallback["level"],
            weeks=fallback["weeks"],
            plan_json=json.dumps(fallback),
        )
        db.add(plan)
        await db.commit()
        await db.refresh(plan)

        return TrainingPlanResponse(
            planID=plan.planID,
            clientID=client_id,
            title=plan.title,
            goal=plan.goal,
            level=plan.level,
            weeks=plan.weeks,
            plan=_parse_weeks(fallback.get("plan", []), req.days_per_week),
            raw_json=plan.plan_json,
            created_at=plan.created_at,
        )


# ── Helpers ───────────────────────────────────────────────────────────────────

def _safe_parse_json(text: str) -> dict:
    """Parse Gemini JSON, aggressively repairing truncated output."""
    # 1. Strip markdown fences
    text = text.replace("```json", "").replace("```", "").strip()

    # 2. Isolate the JSON object
    start_idx = text.find("{")
    end_idx = text.rfind("}")
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        text = text[start_idx : end_idx + 1]
    elif start_idx != -1:
        text = text[start_idx:]

    # 3. Try direct parse first
    try:
        return json.loads(text)
    except json.JSONDecodeError as e:
        logger.warning("JSON parse failed (will attempt repair): %s | snippet: %s", e, text[:250])

    # 4. Aggressive repair for truncated responses
    repaired = _try_repair_truncated_json(text)
    try:
        result = json.loads(repaired)
        weeks = result.get("plan", [])
        if weeks:
            logger.info("JSON repair succeeded — salvaged %d week(s)", len(weeks))
        return result
    except json.JSONDecodeError as repair_err:
        logger.error("JSON repair also failed: %s", repair_err)
        return {"title": "Plan (partial – AI response was truncated)", "plan": []}


def _try_repair_truncated_json(text: str) -> str:
    """Aggressively repair truncated JSON from Gemini by stripping the
    incomplete tail and properly closing all open brackets / braces."""
    import re

    # ── Step 1: Strip any trailing incomplete string value ──────────────────
    # If the text ends mid-string (no closing quote), remove back to the
    # last complete key-value or array element.
    # Count unescaped quotes – odd means we're inside a string
    quote_count = 0
    i = 0
    while i < len(text):
        if text[i] == '"' and (i == 0 or text[i - 1] != '\\'):
            quote_count += 1
        i += 1
    if quote_count % 2 == 1:  # inside an unclosed string
        last_quote = text.rfind('"')
        text = text[:last_quote]  # chop the opening quote of the broken string

    # ── Step 2: Strip trailing partial tokens ──────────────────────────────
    # Remove trailing chars that can't end a valid JSON value
    text = re.sub(r'[,:\s"]+$', '', text)

    # ── Step 3: Remove the last incomplete object/array element ────────────
    # Walk backwards and remove any dangling key-only or partial entry
    # e.g.  {"name": "Push-ups", "sets":   ← remove the broken element
    # Strategy: repeatedly strip trailing junk until the tail is a valid
    # JSON closing char (}, ], digit, true, false, null, or quoted string)
    for _ in range(10):  # safety bound
        stripped = text.rstrip()
        if not stripped:
            break
        last_char = stripped[-1]
        if last_char in ('}', ']', '"') or stripped[-4:] in ('true', 'null') or stripped[-5:] == 'false' or last_char.isdigit():
            break
        # Remove the last token (key, colon, comma, partial value)
        text = re.sub(r'[,}\]]*\s*[^,}\]\[{]*$', '', stripped, count=1)

    # ── Step 4: Remove any trailing commas before we close ─────────────────
    text = re.sub(r',\s*$', '', text)

    # ── Step 5: Balance brackets and braces ────────────────────────────────
    open_braces = text.count('{') - text.count('}')
    open_brackets = text.count('[') - text.count(']')

    # Close innermost structures first: ] then }
    # We interleave based on what was opened last
    closers = []
    stack = []
    for ch in text:
        if ch == '{':
            stack.append('}')
        elif ch == '[':
            stack.append(']')
        elif ch in ('}', ']') and stack:
            stack.pop()

    # stack now has the closers we need, in order (innermost last)
    text += ''.join(reversed(stack))

    return text


def _parse_weeks(weeks_list: list, days_per_week: int = 5) -> list[WeekPlan]:
    if not weeks_list:
        return []

    first = weeks_list[0]
    is_flat = "day" in first and "days" not in first

    if is_flat:
        out: list[WeekPlan] = []
        for w_idx in range(0, len(weeks_list), days_per_week):
            chunk = weeks_list[w_idx : w_idx + days_per_week]
            days = [
                DayPlan(
                    day=str(d.get("day", i + 1)),
                    focus=d.get("focus", ""),
                    exercises=d.get("exercises", []),
                    notes=d.get("notes"),
                )
                for i, d in enumerate(chunk)
            ]
            out.append(WeekPlan(week=w_idx // days_per_week + 1, theme=None, days=days))
        return out

    out: list[WeekPlan] = []
    for w in weeks_list:
        days = [
            DayPlan(
                day=str(d.get("day", "")),
                focus=d.get("focus", ""),
                exercises=d.get("exercises", []),
                notes=d.get("notes"),
            )
            for d in w.get("days", [])
        ]
        out.append(WeekPlan(week=w.get("week", 0), theme=w.get("theme"), days=days))
    return out


gemini_agent = GeminiTrainingAgent()
