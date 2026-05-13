from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.params import Depends
from app.database import get_session
from app.routers import auth
from app.routers import coach_dashboard,coach_schedule
from app.routers import gym


app = FastAPI(title="Titan Gym Management System")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.routers import (
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

