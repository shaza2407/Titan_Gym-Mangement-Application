
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_session
from app.models import User, Client, Coach, Admin
from app.schemas import SignUpRequest, SignUpResponse, SignInRequest, SignInResponse 
from app.schemas.ForgotPasswordRequest import ForgotPasswordRequest
from app.schemas.ResetPasswordRequest import ResetPasswordRequest
from passlib.context import CryptContext
from jose import jwt
import datetime
from backend.app.models.Gym import Gym
from backend.app.models.gym_clients_membership import GymClientMembership
import bcrypt
from app.email_utils import send_verification_email, send_reset_email
import secrets


router = APIRouter(prefix="/auth", tags=["Auth"])           #path prefix for all routes in this file, and tag for docs
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
SECRET_KEY = "your-secret-key"      #will be used in production, should be env var 
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

#POST /auth/signup/
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
            role=payload.role.value,
            phone=payload.phone,
            is_verified=False         #set to False until they verify their email
        )
        db.add(user)
        await db.flush()  
        if payload.role.value == "client":
            client = Client(
                userID=user.userID
            )
            db.add(client)

        elif payload.role.value == "coach":
            coach = Coach(userID=user.userID)
            db.add(coach)

        elif payload.role.value == "admin":
            admin = Admin(userID=user.userID)
            db.add(admin)

        #generate verification token, save to user record, and send email          
        verify_token = secrets.token_urlsafe(32)
        user.reset_token     = verify_token
        user.reset_token_exp = datetime.datetime.utcnow() + datetime.timedelta(hours=24)

        await db.commit()       #commit all changes (user + role-specific + token)
        await db.refresh(user)

        #send verification email              
        await send_verification_email(user.email, verify_token)
    except Exception:
        await db.rollback()     
        raise

    return SignUpResponse(
        userID=user.userID,
        email=user.email,
        phone=user.phone,
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

    if not user.is_verified:
        raise HTTPException(403, "Please verify your email before signing in")
    
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
    return SignInResponse(access_token = token,token_type = "bearer",role = role,userID= user.userID)
    # check gym connection for clients
    # is_gym_connected = False
    # gymID            = None
    # gymName          = None
    # clientID         = None

    # if role == "client":
    #     # get clientID
    #     client_result = await db.execute(
    #         select(Client).filter(Client.userID == user.userID)
    #     )
    #     client = client_result.scalar_one_or_none()

    #     if client:
    #         clientID = client.clientID
    #         # check if connected to any active gym
    #         link_result = await db.execute(
    #             select(GymClient).filter(
    #                 GymClient.clientID == client.clientID,
    #                 GymClient.status   == "active"
    #             )
    #         )
    #         gym_link = link_result.scalar_one_or_none()

    #         if gym_link:
    #             is_gym_connected = True
    #             gymID            = gym_link.gymID
    #             # fetch gym name
    #             gym_result = await db.execute(
    #                 select(Gym).filter(Gym.gymID == gym_link.gymID)
    #             )
    #             gym     = gym_result.scalar_one_or_none()
    #             gymName = gym.gymName if gym else None

    # return SignInResponse(
    #     access_token     = token,
    #     token_type       = "bearer",
    #     role             = role,
    #     userID           = user.userID,
    #     is_gym_connected = is_gym_connected,
    #     gymID            = gymID,
    #     gymName          = gymName,
    #     clientID         = clientID,
    # )


#GET /auth/verify-email?token=***
@router.get("/verify-email")
async def verify_email(token: str, db: AsyncSession = Depends(get_session)):

    result = await db.execute(select(User).where(User.reset_token == token))   

    user = result.scalar_one_or_none()          #find user with matching token 
    if not user:                                #if no user found, token is invalid 
        raise HTTPException(status_code=400, detail="Invalid verification link")

    if user.reset_token_exp < datetime.datetime.utcnow():               #verification link expires in 24 hours
        raise HTTPException(status_code=400, detail="Verification link has expired")

    if user.is_verified:                    #if already verified email
        return {"message": "Email already verified"}

    user.is_verified = True         #verify email 
    user.reset_token = None         #clear token
    user.reset_token_exp = None
    await db.commit()
    return {"message": "Email verified successfully! You can now sign in."}


#POST /auth/forgot-password
@router.post("/forgot-password")
async def forgot_password(payload: ForgotPasswordRequest, db: AsyncSession = Depends(get_session)):

    result = await db.execute(select(User).where(User.email == payload.email.lower()))  #find user by email
    user = result.scalar_one_or_none()      

    if not user:
        return {"message": "If that email is registered, a reset link has been sent."} #not revealing whether email exists or not for security reasons

    token = secrets.token_urlsafe(32)       #generate reset token 
    user.reset_token = token                #save token and expiration time (30 minutes) to user
    user.reset_token_exp = datetime.datetime.utcnow() + datetime.timedelta(minutes=30)
    await db.commit()

    await send_reset_email(user.email, token)       #send reset email with token link
    return {"message": "If that email is registered, a reset link has been sent."}


#POST /auth/reset-password
@router.post("/reset-password")
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_session)):

    result = await db.execute(select(User).where(User.reset_token == payload.token))        #find user with matching reset token
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    if user.reset_token_exp < datetime.datetime.utcnow():
        raise HTTPException(status_code=400, detail="Token has expired")

    user.password = pwd_context.hash(payload.new_password)      #update password
    user.reset_token = None                 #clear reset token and expiration
    user.reset_token_exp = None
    await db.commit()

    return {"message": "Password reset successfully. You can now sign in."}