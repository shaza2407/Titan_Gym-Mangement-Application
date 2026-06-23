# app/services/coach_profile.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.coach import Coach
from app.models import User
from app.schemas.coach.coach_schemas import CoachProfileUpdate


def _split_specializations(value: str | None) -> list[str] | None:
    if not value:
        return None
    return [s.strip() for s in value.split(",") if s.strip()]


def _join_specializations(value: list[str] | None) -> str | None:
    if not value:
        return None
    return ",".join(value)


async def get_coach_profile(userID: int, db: AsyncSession) -> dict | None:
    user_result = await db.execute(select(User).where(User.userID == userID))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    coach_result = await db.execute(select(Coach).where(Coach.userID == userID))
    coach = coach_result.scalar_one_or_none()
    if not coach:
        return None

    return {
        "userID":           user.userID,
        "coachID":          coach.coachID,
        "name":             user.name,
        "email":            user.email,
        "phone":            user.phone,
        "bio":              coach.bio,
        "specializations":  _split_specializations(coach.specializations),
        "certifications":   coach.certifications,
        "years_experience": coach.years_experience,
        "date_of_birth":    coach.date_of_birth,
    }


async def update_coach_profile(
    userID: int,
    payload: CoachProfileUpdate,
    db: AsyncSession
) -> dict | None:
    user_result = await db.execute(select(User).where(User.userID == userID))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    coach_result = await db.execute(select(Coach).where(Coach.userID == userID))
    coach = coach_result.scalar_one_or_none()
    if not coach:
        return None

    if payload.name is not None:
        user.name = payload.name
    if payload.phone is not None:
        user.phone = payload.phone
    if payload.bio is not None:
        coach.bio = payload.bio
    if payload.specializations is not None:
        coach.specializations = _join_specializations(payload.specializations)
    if payload.certifications is not None:
        coach.certifications = payload.certifications
    if payload.years_experience is not None:
        coach.years_experience = payload.years_experience
    if payload.date_of_birth is not None:
        coach.date_of_birth = payload.date_of_birth

    await db.commit()
    await db.refresh(user)
    await db.refresh(coach)

    return await get_coach_profile(userID, db)