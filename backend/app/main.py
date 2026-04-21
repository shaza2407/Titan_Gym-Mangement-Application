from fastapi import FastAPI
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi.params import Depends
from app.models import User
from app.schemas.user import UserCreate

from app.database import get_session

app = FastAPI()


@app.get("/")
def read_root():
    return {"message": "Welcome to my FastAPI backend"}


@app.get("/health")
async def health_check(session: AsyncSession = Depends(get_session)):
    table = await session.scalars(text("SELECT 1"))
    return {"status": "ok", "db_response": table.all()}



@app.post("/users")
async def create_user(user: UserCreate,session: AsyncSession = Depends(get_session)):
    new_user = User(name=user.name,email=user.email)

    session.add(new_user)
    await session.commit()
    await session.refresh(new_user)

    return {
        "id": new_user.id,
        "name": new_user.name,
        "email": new_user.email
    }
