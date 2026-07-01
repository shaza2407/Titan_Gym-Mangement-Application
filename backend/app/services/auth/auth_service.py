from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.models import User, Client, Coach, Admin
from app.schemas.auth import SignUpResponse
from app.schemas.auth.ForgotPasswordRequest import ForgotPasswordRequest
from app.schemas.auth.ResendVerficationRequest import ResendVerificationRequest    
from app.schemas.auth.VerifyEmailRequest import VerifyEmailRequest
from passlib.context import CryptContext
from jose import jwt
import datetime
import bcrypt , os
import random
from app.dependencies.email_utils import send_verification_email, send_reset_email
from datetime import datetime, timedelta ,timezone
from app.schemas.auth.SignInResponse import SignInResponse
from app.schemas.auth.SignInRequest import SignInRequest
from app.schemas.auth.SignUpRequest import SignUpRequest

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = os.getenv("SECRET_KEY")   #will be used in production, should be env var
ALGORITHM  = "HS256"                #JWT signing algorithm, usually HS256 or RS256

#Helper function to detect user role based on their ID
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


# app/services/auth_service.py
async def signup_user(payload: SignUpRequest, db: AsyncSession) -> User:
    # Check if email exists
    result = await db.execute(select(User).where(User.email == payload.email.lower()))
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    try:
        hashed_password = pwd_context.hash(payload.password)
        user = User(
            email=payload.email.lower(),
            name=payload.name,
            password=hashed_password,
            role=payload.role.value,
            phone=payload.phone,
            is_verified=False
        )
        db.add(user)
        await db.flush()

        if payload.role.value == "client":
            db.add(Client(userID=user.userID))
        elif payload.role.value == "coach":
            db.add(Coach(userID=user.userID))
        elif payload.role.value == "admin":
            db.add(Admin(userID=user.userID))

        verify_token = str(random.randint(100000, 999999))
        user.reset_token = verify_token
        user.reset_token_exp = datetime.now(timezone.utc) + timedelta(hours=3)

        await db.commit()
        await db.refresh(user)

        await send_verification_email(user.email, verify_token)

        return user

    except Exception:
        await db.rollback()
        raise



async def signin_user(payload: SignInRequest, db: AsyncSession) -> SignInResponse:
    result = await db.execute(select(User).filter(User.email == payload.email.lower()))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(401, "Invalid email or password")

    if not bcrypt.checkpw(payload.password.encode("utf-8"), user.password.encode("utf-8")):
        raise HTTPException(401, "Invalid email or password")

    if not user.is_verified:
        raise HTTPException(403, "Please verify your email before signing in")

    role = await detect_role(user.userID, db)

    token = jwt.encode(
        {
            "sub": str(user.userID),
            "role": role,
            "exp": datetime.now(timezone.utc) + timedelta(hours=24),
        },
        SECRET_KEY,
        algorithm=ALGORITHM,
    )

    return SignInResponse(
        access_token=token,
        token_type="bearer",
        role=role,
        userID=user.userID,
    )


async def verify_email(request: VerifyEmailRequest, db: AsyncSession) -> dict:
    result = await db.execute(select(User).where(User.email == request.email))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(404, "User not found")

    if user.is_verified:
        return {"message": "Email already verified"}

    if user.reset_token != request.code:
        raise HTTPException(400, "Invalid verification code")

    if user.reset_token_exp < datetime.now(timezone.utc):
        raise HTTPException(400, "Verification code has expired")

    user.is_verified = True
    user.reset_token = None
    user.reset_token_exp = None
    await db.commit()

    return {"message": "Email verified successfully! You can now sign in."}


async def resend_verification(request: ResendVerificationRequest, db: AsyncSession) -> dict:
    result = await db.execute(select(User).where(User.email == request.email))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(404, "Email not found")

    if user.is_verified:
        raise HTTPException(400, "Email already verified")

    code = str(random.randint(100000, 999999))
    user.reset_token = code
    user.reset_token_exp = datetime.now(timezone.utc) + timedelta(hours=24)
    await db.commit()

    await send_verification_email(user.email, code)

    return {"message": "Verification code resent successfully"}


async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession) -> dict:
    result = await db.execute(select(User).where(User.email == payload.email.lower()))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(404, "Email not found")

    code = str(random.randint(100000, 999999))
    user.reset_token = code
    user.reset_token_exp = datetime.now(timezone.utc) + timedelta(minutes=30)
    await db.commit()

    await send_reset_email(user.email, code)

    return {"message": "A reset code has been sent."}