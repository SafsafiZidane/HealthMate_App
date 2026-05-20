from typing import Generic, Optional, TypeVar
from pydantic import BaseModel



T = TypeVar('T')


class Login(BaseModel):
    email: str
    password: str
    

class Register(BaseModel):
    first_name: str
    last_name: str
    username: str
    email: str
    password: str

class ResponseSchema( BaseModel):
    code :str
    status: str
    message: str
    result: Optional[T] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str