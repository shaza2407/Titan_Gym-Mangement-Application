from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from app.database import get_session
from app.models import User

SECRET_KEY = "your-secret-key"
ALGORITHM  = "HS256"

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/signin")


#decode token & return current user
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_session)
) -> User:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        userID  = int(payload.get("sub"))
    except (JWTError, TypeError):
        raise HTTPException(401, "Invalid or expired token")

    user = db.query(User).filter(User.userID == userID).first()
    if not user:
        raise HTTPException(401, "User not found")
    return user


# to use in routes that require specific roles
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