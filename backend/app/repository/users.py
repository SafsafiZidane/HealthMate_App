import os
from dotenv import load_dotenv
from typing import Optional, TypeVar, Generic
from sqlalchemy.orm import Session
from datetime import datetime,timedelta
from jose import jwt,JWTError
from fastapi import HTTPException, Depends,Request
from fastapi.security import HTTPBearer,HTTPBasicCredentials

T = TypeVar('T')

load_dotenv()


class BaseRepo() :
    @staticmethod
    def insert(db: Session, model :Generic[T]):
        db.add(model)
        db.commit()
        db.refresh(model)
        

class UserRepo(BaseRepo):
    @staticmethod
    def find_by_email(db: Session,model :Generic[T], email: str):
        return db.query(model).filter(model.email == email).first()
    

class JWTRepo():
    @staticmethod
    def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=15)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, os.getenv("SECRET_KEY"), algorithm=os.getenv("ALGORITHM"))
        return encoded_jwt
    
    @staticmethod
    def verify_token(token: str):
        try:
            payload = jwt.decode(token, os.getenv("SECRET_KEY"), algorithms=[os.getenv("ALGORITHM")])
            return payload
        except JWTError:
            raise HTTPException(status_code=401, detail="Invalid token")
