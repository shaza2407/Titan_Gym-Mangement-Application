# app/models/__init__.py

# Core Models
from app.models.User import User
from app.models.client import Client
from app.models.coach import Coach
from app.models.Admin import Admin
from app.models.Gym import Gym
# Membership Models
from app.models.gym_clients_membership import GymClientMembership
from app.models.gym_coachs_membership import GymCoachMembership
from app.models.member_invitation import MemberInvitation

# Gym & Classes
from app.models.Machine import Machine
from app.models.gymMachineInventory import GymMachineInventory
from app.models.class_request import ClassRequest
from app.models.class_session import ClassSession
from app.models.client_class_enrollment import ClientClassEnrollment

# Training Plans
from app.models.training_plan import TrainingPlan, PlanStatus
from app.models.training_plan_tracking import (
    TrainingPlanTracking,
    TrainingPlanWeekProgress,
    WorkoutStatus,
    DayStatus,
)

# Achievements & Check-ins
from app.models.achievement import (
    Achievement,
    AchievementCategory,
    AchievementDifficulty,
)

from app.models.client_achievement import ClientAchievement
from app.models.check_in import CheckIn


__all__ = [
    # Core
    "User",
    "Client",
    "Coach",
    "Admin",
    "Gym",

    # Membership
    "GymClientMembership",
    "GymCoachMembership",
    "MemberInvitation",

    # Gym & Classes
    "Machine",
    "GymMachineInventory",
    "ClassRequest",
    "ClassSession",
    "ClientClassEnrollment",

    # Training Plans
    "TrainingPlan",
    "PlanStatus",
    "TrainingPlanTracking",
    "TrainingPlanWeekProgress",
    "WorkoutStatus",
    "DayStatus",

    # Achievements
    "Achievement",
    "AchievementCategory",
    "AchievementDifficulty",
    "ClientAchievement",
    "CheckIn",
]