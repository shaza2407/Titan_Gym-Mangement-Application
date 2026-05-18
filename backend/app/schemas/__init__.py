# app/schemas/__init__.py
from app.schemas.SignUpRequest import SignUpRequest
from app.schemas.SignUpResponse import SignUpResponse
from app.schemas.SignInRequest import SignInRequest
from app.schemas.SignInResponse import SignInResponse
from app.schemas.ForgotPasswordRequest import ForgotPasswordRequest
from app.schemas.ResetPasswordRequest import ResetPasswordRequest
# from app.schemas.ResendVerificationRequest import ResendVerificationRequest
# from app.schemas.VerifyEmailRequest import VerifyEmailRequest

# from app.schemas.TrainingPlanRequest import TrainingPlanRequest
# from app.schemas.TrainingPlanResponse import TrainingPlanResponse
#
# from app.schemas.UserRole import UserRole
#
# from app.schemas.Machine import MachineResponse , MachineUpdate , MachineCreate , MachineBase
# from app.schemas.GymMachineInventory import InventoryResponse , InventoryCreate , InventoryBase , MachineResponse , MachineUpdate
# from app.schemas.gym import GymResponse , GymUpdate , GymCreate , GymBase


# from app.schemas.attendance_schema import *
# from app.schemas.achievement_schemas import *


# app/schemas/__init__.py

from app.schemas import (
    SignUpRequest,
    SignUpResponse,
    SignInRequest,
    SignInResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest
)