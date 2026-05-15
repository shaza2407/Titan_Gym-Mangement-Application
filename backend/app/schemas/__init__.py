# ── Auth & User ───────────────────────────────────────────────────────────────
from app.schemas.UserRole import UserRole
from app.schemas.SignUpRequest import SignUpRequest
from app.schemas.SignUpResponse import SignUpResponse
from app.schemas.SignInRequest import SignInRequest
from app.schemas.SignInResponse import SignInResponse
from app.schemas.ForgotPasswordRequest import ForgotPasswordRequest
from app.schemas.ResetPasswordRequest import ResetPasswordRequest

# ── Gym ───────────────────────────────────────────────────────────────────────
from app.schemas.gym import GymBase, GymCreate, GymUpdate, GymResponse, GymWithMachines

# ── Machine ───────────────────────────────────────────────────────────────────
from app.schemas.Machine import MachineBase, MachineCreate, MachineUpdate, MachineResponse

# ── Gym Machine Inventory ─────────────────────────────────────────────────────
from app.schemas.GymMachineInventory import InventoryBase, InventoryCreate, InventoryResponse

# ── Coach ─────────────────────────────────────────────────────────────────────
from app.schemas.coach_schemas import (
    ClassSessionResponse,
    DashboardStatsResponse,
    ScheduleStatsResponse,
    MyClassesResponse,
    CreateClassRequestPayload,
    ClassRequestResponse,
    InviteCoachRequest,
    InviteCoachResponse,
    CoachListItem,
    CoachListResponse,
)

# ── Achievements ──────────────────────────────────────────────────────────────
from app.schemas.achievement_schemas import (
    AchievementProgressResponse,
    CheckInRequest,
    CheckInResponse,
)

# ── Training Plan ─────────────────────────────────────────────────────────────
from app.schemas.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.TrainingPlanResponse import (
    DayPlan,
    WeekPlan,
    TrainingPlanResponse,
    TrainingPlanSummary,
)

__all__ = [
    # Auth & User
    "UserRole",
    "SignUpRequest", "SignUpResponse",
    "SignInRequest", "SignInResponse",
    "ForgotPasswordRequest", "ResetPasswordRequest",
    # Gym
    "GymBase", "GymCreate", "GymUpdate", "GymResponse", "GymWithMachines",
    # Machine
    "MachineBase", "MachineCreate", "MachineUpdate", "MachineResponse",
    # Inventory
    "InventoryBase", "InventoryCreate", "InventoryResponse",
    # Coach
    "ClassSessionResponse", "DashboardStatsResponse", "ScheduleStatsResponse",
    "MyClassesResponse", "CreateClassRequestPayload", "ClassRequestResponse",
    "InviteCoachRequest", "InviteCoachResponse", "CoachListItem", "CoachListResponse",
    # Achievements
    "AchievementProgressResponse", "CheckInRequest", "CheckInResponse",
    # Training Plan
    "TrainingPlanRequest", "DayPlan", "WeekPlan",
    "TrainingPlanResponse", "TrainingPlanSummary",
]