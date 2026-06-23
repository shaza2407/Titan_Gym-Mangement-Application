"""
app/seed_achievements.py
─────────────────────────
Seeds the achievements table with all 10 chains × 5 levels = 50 rows.

Run once:
    python -m app.seed_achievements

Or call seed_achievements() from an alembic migration's upgrade().
"""

import asyncio
from sqlalchemy import select
from app.database import get_session
from app.models.achievement import Achievement, AchievementCategory, AchievementDifficulty


def _chain(
    chain_key: str,
    name_base: str,
    description: str,
    icon: str,
    category: AchievementCategory,
    targets: list[int],
    unit: str,
    points_per_level: list[int],
) -> list[dict]:
    """Build 5 level rows for one chain."""
    levels = [
        AchievementDifficulty.BRONZE,
        AchievementDifficulty.SILVER,
        AchievementDifficulty.GOLD,
        AchievementDifficulty.PLATINUM,
        AchievementDifficulty.DIAMOND,
    ]
    rows = []
    for i, (diff, target, pts) in enumerate(zip(levels, targets, points_per_level)):
        key      = f"{chain_key}_{diff.value.lower()}"
        prereq   = f"{chain_key}_{levels[i-1].value.lower()}" if i > 0 else None
        rows.append({
            "key"             : key,
            "chain_key"       : chain_key,
            "name"            : f"{name_base} — {diff.value.capitalize()}",
            "description"     : description,
            "icon_emoji"      : icon,
            "category"        : category,
            "difficulty"      : diff,
            "target"          : target,
            "prerequisite_key": prereq,
            "unit"            : unit,
            "points"          : pts,
            "is_active"       : True,
        })
    return rows


ACHIEVEMENTS: list[dict] = []

# 1) Gym Rat – total check-ins
ACHIEVEMENTS += _chain(
    "gym_rat", "Gym Rat",
    "Total gym check-ins",
    "🐀", AchievementCategory.CHECKIN,
    targets=[10, 25, 50, 100, 250],
    unit="visits",
    points_per_level=[30, 60, 100, 200, 500],
)

# 2) Monthly Champion – visits this calendar month
ACHIEVEMENTS += _chain(
    "monthly_champion", "Monthly Champion",
    "Gym visits within the current month",
    "🏆", AchievementCategory.CHECKIN,
    targets=[5, 10, 20, 35, 50],
    unit="visits",
    points_per_level=[25, 50, 100, 175, 300],
)

# 3) Early Bird – check-ins before 07:00
ACHIEVEMENTS += _chain(
    "early_bird", "Early Bird",
    "Check-ins before 7 AM",
    "🌅", AchievementCategory.CHECKIN,
    targets=[5, 15, 30, 60, 100],
    unit="mornings",
    points_per_level=[25, 60, 100, 200, 400],
)

# 4) Night Owl – check-ins at or after 20:00
ACHIEVEMENTS += _chain(
    "night_owl", "Night Owl",
    "Check-ins after 8 PM",
    "🦉", AchievementCategory.CHECKIN,
    targets=[5, 15, 30, 60, 100],
    unit="nights",
    points_per_level=[25, 60, 100, 200, 400],
)

# 5) Weekend Warrior – check-ins on Friday or Saturday
ACHIEVEMENTS += _chain(
    "weekend_warrior", "Weekend Warrior",
    "Check-ins on Fridays or Saturdays",
    "⚔️", AchievementCategory.CHECKIN,
    targets=[5, 15, 30, 60, 100],
    unit="weekends",
    points_per_level=[25, 60, 100, 200, 400],
)

# 6) Consistency – consecutive-day streak
ACHIEVEMENTS += _chain(
    "consistency", "Consistency",
    "Consecutive check-in day streak",
    "🔥", AchievementCategory.STREAK,
    targets=[3, 7, 30, 90, 365],
    unit="days",
    points_per_level=[20, 50, 200, 500, 2000],
)

# 7) Perfect Week – weeks with 5+ distinct check-in days
ACHIEVEMENTS += _chain(
    "perfect_week", "Perfect Week",
    "Check in on 5 different days in a single week",
    "📅", AchievementCategory.CHECKIN,
    targets=[1, 3, 10, 25, 50],
    unit="perfect weeks",
    points_per_level=[30, 80, 200, 400, 800],
)

# 8) Class Enthusiast – total classes attended
ACHIEVEMENTS += _chain(
    "class_enthusiast", "Class Enthusiast",
    "Total group classes enrolled in",
    "🧘", AchievementCategory.CLASS,
    targets=[5, 15, 30, 60, 120],
    unit="classes",
    points_per_level=[25, 60, 120, 250, 500],
)

# 9) Training Plan Completion – completed plans
ACHIEVEMENTS += _chain(
    "training_plan_completion", "Training Plan Completion",
    "Completed AI training plans",
    "📋", AchievementCategory.TRAINING,
    targets=[1, 3, 5, 10, 20],
    unit="plans",
    points_per_level=[50, 120, 200, 400, 800],
)

# 10) Badge Collector – total unlocked badges
ACHIEVEMENTS += _chain(
    "badge_collector", "Badge Collector",
    "Total achievement badges unlocked",
    "🎖️", AchievementCategory.MILESTONE,
    targets=[5, 15, 30, 50, 100],
    unit="badges",
    points_per_level=[30, 80, 150, 300, 600],
)

# 11) Workout Warrior – total workouts completed
ACHIEVEMENTS += _chain(
    "workout_warrior", "Workout Warrior",
    "Total workout days completed",
    "🏋️", AchievementCategory.TRAINING,
    targets=[5, 15, 30, 60, 100],
    unit="workouts",
    points_per_level=[30, 80, 150, 300, 600],
)

# 12) Plan Pioneer – total AI plans generated
ACHIEVEMENTS += _chain(
    "plan_pioneer", "Plan Pioneer",
    "Total AI training plans generated",
    "🤖", AchievementCategory.TRAINING,
    targets=[1, 3, 5, 10, 25],
    unit="plans",
    points_per_level=[20, 50, 100, 250, 500],
)


async def seed_achievements():
    async for db in get_session():
        for data in ACHIEVEMENTS:
            # Skip if key already exists
            res = await db.execute(
                select(Achievement).where(Achievement.key == data["key"])
            )
            if res.scalar_one_or_none():
                continue

            ach = Achievement(**data)
            db.add(ach)

        await db.commit()
        print(f"✅  Seeded {len(ACHIEVEMENTS)} achievement levels.")


if __name__ == "__main__":
    asyncio.run(seed_achievements())