from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.params import Depends
from app.database import get_session
from app.routers.Admin import admin_clients_management
from app.routers.Auth import auth
from app.routers.Coach import coach_dashboard
from app.routers.Admin import admin_coaches_management
from app.routers.Admin import gym
from app.routers.Admin import admin_dashboard
from app.routers.Client import client_dashboard
from app.routers.Client import client_attendance
from app.routers.Client import achievements
from app.routers.Client import training_plan
from app.routers.Admin import admin_schedule
from app.routers.Client import client_schedule
from app.routers.Coach import coach_schedule
from app.routers.Admin import admin_attendence_stat
from app.routers.Notifications import notifications
from app.routers.Admin import admin_analytics
from app.routers.Admin import admin_announcements


app = FastAPI(title="Titan Gym Management System")

app.add_middleware(
    CORSMiddleware,
    # allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.routers.Auth import (
    auth
)

@app.get("/")
def read_root():
    return {"message": "Welcome to my FastAPI backend"}


# Register and log in routers
app.include_router(auth.router)

#coach routers
app.include_router(coach_dashboard.router)
app.include_router(coach_schedule.router)

#gym routers
app.include_router(gym.router)

## GYM members management
app.include_router(admin_clients_management.router)
app.include_router(admin_coaches_management.router)

#client routers
app.include_router(client_dashboard.router)
app.include_router(client_attendance.router)
app.include_router(client_schedule.router)
app.include_router(training_plan.router)
app.include_router(achievements.router)



# admin routers
app.include_router(admin_schedule.router)
app.include_router(admin_dashboard.router)
app.include_router(admin_announcements.router)
app.include_router(admin_attendence_stat.router)
app.include_router(admin_analytics.router)



# Notifications
app.include_router(notifications.router)
