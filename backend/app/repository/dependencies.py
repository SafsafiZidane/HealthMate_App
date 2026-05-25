from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.repository.users import JWTRepo

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/login")

def get_current_user(token: str = Depends(oauth2_scheme)):
    payload = JWTRepo.verify_token(token)  # you need this method (see Step 2)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload  # returns the decoded data e.g. {"sub": "user@email.com"}