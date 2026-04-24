
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.models import User, Client, Coach, Admin
from app.schemas import SignUpRequest, SignUpResponse, SignInRequest, SignInResponse
from passlib.context import CryptContext
from jose import jwt
import datetime
import bcrypt


router = APIRouter(prefix="/auth", tags=["Auth"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "your-secret-key"
ALGORITHM  = "HS256"


#Helper (put here, above all routes)
async def detect_role(userID: int, db: AsyncSession) -> str:
    result = await db.execute(select(Client).filter(Client.userID == userID))
    if result.scalar_one_or_none():
        return "client"

    result = await db.execute(select(Coach).filter(Coach.userID == userID))
    if result.scalar_one_or_none():
        return "coach"

    result = await db.execute(select(Admin).filter(Admin.userID == userID))
    if result.scalar_one_or_none():
        return "admin"

    raise HTTPException(400, "User has no assigned role")


#POST /auth/signup 
@router.post("/signup", response_model=SignUpResponse)
async def signup(payload: SignUpRequest, db: AsyncSession = Depends(get_session)):  

    # Check if email exists
    result = await db.execute(select(User).where(User.email == payload.email.lower()))
    existing_user = result.scalar_one_or_none()
    print(payload)
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    try:
        hashed_password = pwd_context.hash(payload.password)
        user = User(
            email=payload.email.lower(),
            name=payload.name,
            password=hashed_password,
            role=payload.role.value   
        )
        db.add(user)
        await db.flush()  

        if payload.role.value == "client":
            client = Client(
                userID=user.userID,
                fitness_goal=payload.fitness_goal,
                age=payload.age,
                gender=payload.gender
            )
            db.add(client)

        elif payload.role.value == "coach":
            coach = Coach(userID=user.userID)
            db.add(coach)

        elif payload.role.value == "admin":
            admin = Admin(userID=user.userID)
            db.add(admin)

        await db.commit()
        await db.refresh(user)

    except Exception:
        await db.rollback()
        raise

    return SignUpResponse(
        userID=user.userID,
        email=user.email,
        name=user.name,
        role=user.role
    )
#POST /auth/signin

@router.post("/signin", response_model=SignInResponse)
async def signin(payload: SignInRequest, db: AsyncSession = Depends(get_session)):  # ← add async

    result = await db.execute(select(User).filter(User.email == payload.email.lower()))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(401, "Invalid email or password")

    if not bcrypt.checkpw(payload.password.encode("utf-8"), user.password.encode("utf-8")):
        raise HTTPException(401, "Invalid email or password")

    #Detect role
    role = await detect_role(user.userID, db)
    #create JWT token
    token = jwt.encode(
        {
            "sub"  : str(user.userID),
            "role" : role,
            "exp"  : datetime.datetime.utcnow() + datetime.timedelta(hours=24)
        },
        SECRET_KEY,
        algorithm=ALGORITHM
    )
    return SignInResponse(access_token=token,token_type="bearer",role=role,userID=user.userID)