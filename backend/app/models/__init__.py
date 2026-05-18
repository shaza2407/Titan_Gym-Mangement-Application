# app/models/__init__.py
# ──────────────────────────────────────────────────────────────────────────────
# NOTE: gym_machine.py is intentionally excluded — its Gym & GymMachine
# classes conflicted with Gym.py and gymMachineInventory.py which the project
# already uses.  Equipment look-up now relies on:
#   • Machine             (app/models/Machine.py)
#   • GymMachineInventory (app/models/gymMachineInventory.py)
# ──────────────────────────────────────────────────────────────────────────────

# Core
from app.models.User import User
from app.models.client import Client
from app.models.coach import Coach
from app.models.Admin import Admin
from app.models.Gym import Gym

# Membership
from app.models.gym_clients_membership import GymClientMembership
from app.models.gym_coachs_membership import GymCoachMembership
from app.models.member_invitation import MemberInvitation

# Equipment (gymMachineInventory uses Machine + Gym — do NOT import gym_machine.py)
from app.models.Machine import Machine
from app.models.gymMachineInventory import GymMachineInventory

# Classes
from app.models.class_request import ClassRequest
from app.models.class_session import ClassSession
from app.models.attendance import Attendance

# Training Plans (versioned)
from app.models.training_plan import (
    TrainingPlan,
    PlanStatus,
    TrainingPlanTracking,
    TrainingPlanWeekProgress,
    WorkoutStatus,
    DayStatus,
)

# Achievements
from app.models.achievement import (
    Achievement,
    AchievementCategory,
    AchievementDifficulty,
)
from app.models.client_achievement import ClientAchievement


__all__ = [
    # Core
    "User", "Client", "Coach", "Admin", "Gym",

    # Membership
    "GymClientMembership", "GymCoachMembership", "MemberInvitation",

    # Equipment
    "Machine", "GymMachineInventory",

    # Classes
    "ClassRequest", "ClassSession", "Attendance",

    # Training Plans
    "TrainingPlan", "PlanStatus",
    "TrainingPlanTracking", "TrainingPlanWeekProgress",
    "WorkoutStatus", "DayStatus",

    # Achievements
    "Achievement", "AchievementCategory", "AchievementDifficulty",
    "ClientAchievement",
]
