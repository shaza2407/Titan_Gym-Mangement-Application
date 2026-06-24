from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_session
from app.schemas.auth import SignUpResponse
from app.schemas.auth.ForgotPasswordRequest import ForgotPasswordRequest
from app.schemas.auth.ResendVerficationRequest import ResendVerificationRequest    
from app.schemas.auth.VerifyEmailRequest import VerifyEmailRequest
from app.services.auth.auth_service import signup_user , signin_user ,forgot_password ,resend_verification ,verify_email
from app.schemas.auth.SignInResponse import SignInResponse
from app.schemas.auth.SignInRequest import SignInRequest
from app.schemas.auth.SignUpRequest import SignUpRequest
from app.schemas.auth.SignUpResponse import SignUpResponse

router = APIRouter(prefix="/auth", tags=["Auth"])           #path prefix for all routes in this file, and tag for docs


# app/routers/Auth/auth.py

#POST /auth/signup/
@router.post("/signup", response_model=SignUpResponse)
async def signup(payload: SignUpRequest, db: AsyncSession = Depends(get_session)):
    user = await signup_user(payload, db)
    return SignUpResponse(
        userID=user.userID,
        email=user.email,
        phone=user.phone,
        name=user.name,
        role=user.role,
    )


#POST /auth/signin
@router.post("/signin", response_model=SignInResponse)
async def signin(payload: SignInRequest, db: AsyncSession = Depends(get_session)):
    return await signin_user(payload, db)



#POST /auth/verify-email
@router.post("/verify-email")
async def verify_email_route(request: VerifyEmailRequest, db: AsyncSession = Depends(get_session)):
    return await verify_email(request, db)


#POST /auth/resend-verification
@router.post("/resend-verification")
async def resend_verification_route(request: ResendVerificationRequest, db: AsyncSession = Depends(get_session)):
    return await resend_verification(request, db)


#POST /auth/forgot-password
@router.post("/forgot-password")
async def forgot_password_route(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_session)):
    return await forgot_password(payload, db)