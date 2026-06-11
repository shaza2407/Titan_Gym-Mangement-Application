from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import jwt, JWTError
from app.database import get_session
from app.models import User
from app.models.Admin import Admin
from app.models.coach import Coach


SECRET_KEY = "your-secret-key"
ALGORITHM  = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/signin")


# async def get_current_user(
#     token: str = Depends(oauth2_scheme),
#     db: AsyncSession = Depends(get_session)
# ) -> Admin:
#     try:
#         payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
#         userID = int(payload.get("sub"))
#     except (JWTError, TypeError):
#         raise HTTPException(401, "Invalid or expired token")

#     # First get the User
#     result = await db.execute(select(User).filter(User.userID == userID))
#     user = result.scalars().first()
#     if not user:
#         raise HTTPException(401, "User not found")

#     # Then get the linked Admin
#     result = await db.execute(select(Admin).filter(Admin.userID == user.userID))
#     admin = result.scalars().first()
#     if not admin:
#         raise HTTPException(403, "User is not an admin")

#     return admin  # ✅ now has .adminID

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_session)
) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        userID  = int(payload.get("sub"))
    except (JWTError, TypeError):
        raise HTTPException(401, "Invalid or expired token")

    result = await db.execute(select(User).filter(User.userID == userID))
    user = result.scalars().first()
    if not user:
        raise HTTPException(401, "User not found")
    return user


async def require_admin(token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_session)
) -> Admin:
    user = await get_current_user(token=token, db=db)
    if user.role != "admin":
        raise HTTPException(403, "Admins only")
    result = await db.execute(select(Admin).filter(Admin.userID == user.userID))
    admin = result.scalars().first()
    if not admin:
        raise HTTPException(404, "Admin record not found")
    return admin  

async def require_coach(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_session)
) -> User:  # ← User not Coach
    user = await get_current_user(token=token, db=db)
    if user.role != "coach":
        raise HTTPException(403, "Coaches only")

    result = await db.execute(select(Coach).filter(Coach.userID == user.userID))
    coach = result.scalars().first()
    if not coach:
        raise HTTPException(404, "Coach record not found")

    return user

async def require_client(current_user: User = Depends(get_current_user)):
    if current_user.role != "client":
        raise HTTPException(403, "Clients only")
    return current_user