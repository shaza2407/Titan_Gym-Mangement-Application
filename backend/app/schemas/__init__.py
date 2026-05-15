from app.models.User import User
from app.models.client import Client
from app.models.coach import Coach
from app.models.Admin import Admin
from app.models.Gym import Gym
from app.models.gym_clients_membership import GymClientMembership
from app.models.gym_coachs_membership import GymCoachMembership
from app.models.member_invitation import MemberInvitation
from app.models.Machine import Machine
from app.models.gymMachineInventory import GymMachineInventory
from app.models.class_request import ClassRequest
from app.models.class_session import ClassSession

# New Models for Achievements and Training Plans
from app.models.achievement import Achievement, UserAchievement, UserCheckIn, UserTrainingPlanProgress
from app.models.gym_machine import GymMachine
from app.models.training_plan import TrainingPlan

# We use strings in __all__ to identify the classes exported by this module
__all__ = [
    "User", "Client", "Coach", "Admin", "Gym", "Machine",
    "GymClientMembership", "GymCoachMembership", "MemberInvitation",
    "GymMachineInventory", "ClassRequest", "ClassSession",
    "Achievement", "UserAchievement", "UserCheckIn",
    "UserTrainingPlanProgress", "GymMachine", "TrainingPlan"
]