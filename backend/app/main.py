from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import routers from all branches
from app.routers import (
    auth,
    training_plan,
    achievements,
    checkin,
    coach_dashboard,
    coach_schedule,
    gym,
    admin_clients_management,
    admin_coaches_management
)

import app.models  # noqa: F401

app = FastAPI(title="Titan Gym Management System")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Welcome to my FastAPI backend"}


# Register and log in routers
app.include_router(auth.router)

# Features (AI Training & Gamification)
app.include_router(training_plan.router)
app.include_router(achievements.router)
app.include_router(checkin.router)
#coach routers
app.include_router(coach_dashboard.router)
app.include_router(coach_schedule.router)

#gym routers
app.include_router(gym.router)

## GYM members management
app.include_router(admin_clients_management.router)
app.include_router(admin_coaches_management.router)