from typing import Generic, Optional, TypeVar
from pydantic import BaseModel
from app.tables.users import UserRole
from app.models.consultation import DoctorProfileBase



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


class AdminCreateUser(Register):
    """
    Used only in protected admin dashboards to manually create 
    doctors, admins, or standard users.
    """
    role: UserRole = UserRole.USER
    doctor_profile: Optional[DoctorProfileBase] = None
