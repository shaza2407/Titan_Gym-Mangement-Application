"""
app/seed_achievements.py
Updated with achievement types and tracking configuration
"""

import asyncio
from sqlalchemy import select
from app.database import get_session
from app.models.achievement import Achievement, AchievementCategory, AchievementDifficulty

ACHIEVEMENTS = [
    # ============ CHECK-IN ACHIEVEMENTS ============
    {
        "achievementID": 1,
        "key": "monthly_champion",
        "name": "Monthly Champion",
        "description": "Check in 20 times in a month",
        "icon_emoji": "🏆",
        "category": AchievementCategory.CHECKIN,
        "difficulty": AchievementDifficulty.GOLD,
        "target": 20,
        "unit": "visits",
        "points": 100,
        "tracking_type": "counter",
        "tracking_config": {"time_window": "monthly", "reset_frequency": "monthly"}
    },
    {
        "achievementID": 2,
        "key": "early_bird",
        "name": "Early Bird",
        "description": "Check in before 7 AM ten times",
        "icon_emoji": "🌅",
        "category": AchievementCategory.CHECKIN,
        "difficulty": AchievementDifficulty.SILVER,
        "target": 10,
        "unit": "mornings",
        "points": 75,
        "tracking_type": "counter",
        "tracking_config": {"time_filter": "hour < 7"}
    },
    {
        "achievementID": 3,
        "key": "night_owl",
        "name": "Night Owl",
        "description": "Check in after 8 PM ten times",
        "icon_emoji": "🦉",
        "category": AchievementCategory.CHECKIN,
        "difficulty": AchievementDifficulty.SILVER,
        "target": 10,
        "unit": "nights",
        "points": 75,
        "tracking_type": "counter",
        "tracking_config": {"time_filter": "hour >= 20"}
    },
    {
        "achievementID": 4,
        "key": "weekend_warrior",
        "name": "Weekend Warrior",
        "description": "Check in on weekends 15 times",
        "icon_emoji": "⚔️",
        "category": AchievementCategory.CHECKIN,
        "difficulty": AchievementDifficulty.SILVER,
        "target": 15,
        "unit": "weekends",
        "points": 80,
        "tracking_type": "counter",
        "tracking_config": {"days_of_week": ["saturday", "sunday"]}
    },
    {
        "achievementID": 5,
        "key": "gym_rat",
        "name": "Gym Rat",
        "description": "Total 100 check-ins overall",
        "icon_emoji": "🐀",
        "category": AchievementCategory.MILESTONE,
        "difficulty": AchievementDifficulty.GOLD,
        "target": 100,
        "unit": "visits",
        "points": 150,
        "tracking_type": "counter",
        "tracking_config": {"time_window": "all_time"}
    },
    {
        "achievementID": 6,
        "key": "explorer",
        "name": "Explorer",
        "description": "Visit 3 different gym locations",
        "icon_emoji": "🗺️",
        "category": AchievementCategory.EXPLORATION,
        "difficulty": AchievementDifficulty.BRONZE,
        "target": 3,
        "unit": "locations",
        "points": 50,
        "tracking_type": "unique",
        "tracking_config": {"field": "gymID"}
    },

    # ============ STREAK ACHIEVEMENTS ============
    {
        "achievementID": 7,
        "key": "consistency_king",
        "name": "Consistency King",
        "description": "Maintain a 30-day check-in streak",
        "icon_emoji": "👑",
        "category": AchievementCategory.STREAK,
        "difficulty": AchievementDifficulty.GOLD,
        "target": 30,
        "unit": "days",
        "points": 200,
        "tracking_type": "streak",
        "tracking_config": {"streak_type": "consecutive_days"}
    },
    {
        "achievementID": 8,
        "key": "dedication",
        "name": "Dedication",
        "description": "Complete a 90-day check-in streak",
        "icon_emoji": "💪",
        "category": AchievementCategory.STREAK,
        "difficulty": AchievementDifficulty.PLATINUM,
        "target": 90,
        "unit": "days",
        "points": 500,
        "tracking_type": "streak",
        "tracking_config": {"streak_type": "consecutive_days"},
        "prerequisite_key": "consistency_king"
    },
    {
        "achievementID": 9,
        "key": "super_streak",
        "name": "Super Streak",
        "description": "Complete a 365-day check-in streak (full year!)",
        "icon_emoji": "🔥",
        "category": AchievementCategory.STREAK,
        "difficulty": AchievementDifficulty.DIAMOND,
        "target": 365,
        "unit": "days",
        "points": 1000,
        "tracking_type": "streak",
        "tracking_config": {"streak_type": "consecutive_days"},
        "prerequisite_key": "dedication",
        "is_hidden": True,
        "reveal_at_percentage": 50
    },
    {
        "achievementID": 10,
        "key": "perfect_week",
        "name": "Perfect Week",
        "description": "Check in 5 days in a single week",
        "icon_emoji": "💯",
        "category": AchievementCategory.CHECKIN,
        "difficulty": AchievementDifficulty.SILVER,
        "target": 1,
        "unit": "weeks",
        "points": 100,
        "tracking_type": "composite",
        "tracking_config": {"time_window": "weekly", "required_days": 5}
    },

    # ============ CLASS ACHIEVEMENTS ============
    {
        "achievementID": 11,
        "key": "class_enthusiast",
        "name": "Class Enthusiast",
        "description": "Attend 10 different classes",
        "icon_emoji": "⭐",
        "category": AchievementCategory.CLASS,
        "difficulty": AchievementDifficulty.GOLD,
        "target": 10,
        "unit": "classes",
        "points": 120,
        "tracking_type": "unique",
        "tracking_config": {"field": "class_title"}
    },
    {
        "achievementID": 12,
        "key": "social_butterfly",
        "name": "Social Butterfly",
        "description": "Participate in 5 group classes",
        "icon_emoji": "🦋",
        "category": AchievementCategory.SOCIAL,
        "difficulty": AchievementDifficulty.BRONZE,
        "target": 5,
        "unit": "classes",
        "points": 80,
        "tracking_type": "counter",
        "tracking_config": {"class_type": "group"}
    },

    # ============ TRAINING PLAN ACHIEVEMENTS ============
    {
        "achievementID": 13,
        "key": "goal_crusher",
        "name": "Goal Crusher",
        "description": "Complete 3 training plans",
        "icon_emoji": "⚡",
        "category": AchievementCategory.TRAINING,
        "difficulty": AchievementDifficulty.GOLD,
        "target": 3,
        "unit": "plans",
        "points": 150,
        "tracking_type": "counter",
        "tracking_config": {"status": "completed"}
    },
    {
        "achievementID": 14,
        "key": "master_trainer",
        "name": "Master Trainer",
        "description": "Complete 5 different training plan types",
        "icon_emoji": "🎓",
        "category": AchievementCategory.TRAINING,
        "difficulty": AchievementDifficulty.PLATINUM,
        "target": 5,
        "unit": "plan types",
        "points": 300,
        "tracking_type": "unique",
        "tracking_config": {"field": "goal"},
        "prerequisite_key": "goal_crusher"
    },
    {
        "achievementID": 15,
        "key": "perfect_plan",
        "name": "Perfect Plan",
        "description": "Complete a training plan with 100% attendance",
        "icon_emoji": "📋",
        "category": AchievementCategory.TRAINING,
        "difficulty": AchievementDifficulty.GOLD,
        "target": 1,
        "unit": "plans",
        "points": 200,
        "tracking_type": "composite",
        "tracking_config": {"completion_percentage": 100}
    },

    # ============ HIDDEN/CHALLENGE ACHIEVEMENTS ============
    {
        "achievementID": 16,
        "key": "secret_workout",
        "name": "Secret Workout",
        "description": "???",  # Hidden until unlocked
        "icon_emoji": "🔒",
        "category": AchievementCategory.MILESTONE,
        "difficulty": AchievementDifficulty.DIAMOND,
        "target": 1,
        "unit": "secret",
        "points": 500,
        "tracking_type": "counter",
        "tracking_config": {"special_condition": "workout_at_midnight"},
        "is_hidden": True,
        "reveal_at_percentage": 0
    }
]


async def seed_achievements():
    async for db in get_session():
        for data in ACHIEVEMENTS:
            existing = await db.execute(
                select(Achievement).where(Achievement.key == data["key"])
            )
            if existing.scalar_one_or_none() is None:
                achievement = Achievement(**data)
                db.add(achievement)
                print(f"✅ Added achievement: {data['name']} ({data['category']} - {data['difficulty']})")
            else:
                print(f"⏭️ Achievement already exists: {data['name']}")

        await db.commit()
        print(f"\n✨ Achievement seed complete! Total: {len(ACHIEVEMENTS)} achievements")


if __name__ == "__main__":
    asyncio.run(seed_achievements())