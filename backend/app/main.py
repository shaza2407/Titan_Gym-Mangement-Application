from fastapi import FastAPI
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.params import Depends
from app.database import get_session
from app.routers import auth


app = FastAPI(title="Titan Gym Management System")

from app.routers import (
    auth
)

@app.get("/")
def read_root():
    return {"message": "Welcome to my FastAPI backend"}


# Register routers
app.include_router(auth.router)

