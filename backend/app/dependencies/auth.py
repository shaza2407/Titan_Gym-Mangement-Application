from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from jose import jwt, JWTError

from app.database import get_session
from app.models import User

SECRET_KEY = "your-secret-key"
ALGORITHM  = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/signin")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_session)
) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        userID  = int(payload.get("sub"))
    except (JWTError, TypeError):
        raise HTTPException(401, "Invalid or expired token")

    result = await db.execute(
        select(User).where(User.userID == userID)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(401, "User not found")

    return user


def require_admin(current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(403, "Admins only")
    return current_user


def require_coach(current_user: User = Depends(get_current_user)):
    if current_user.role != "coach":
        raise HTTPException(403, "Coaches only")
    return current_user


def require_client(current_user: User = Depends(get_current_user)):
    if current_user.role != "client":
        raise HTTPException(403, "Clients only")
    return current_user