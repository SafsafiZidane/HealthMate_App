from datetime import datetime
from typing import Generic, Optional, TypeVar
from pydantic import BaseModel
from app.tables.users import UserRole
from app.models.consultation import DoctorProfileBase, DoctorProfileOut



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


class UserOut(BaseModel):
    id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: str
    email: str
    role: UserRole
    created_at: datetime
    doctor_profile: Optional[DoctorProfileOut] = None

    class Config:
        from_attributes = True


class AdminCreateUser(Register):
    """
    Used only in protected admin dashboards to manually create 
    doctors, admins, or standard users.
    """
    role: UserRole = UserRole.USER
    doctor_profile: Optional[DoctorProfileBase] = None


class AdminUpdateUser(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    role: Optional[UserRole] = None
    doctor_profile: Optional[DoctorProfileBase] = None


class AdminStats(BaseModel):
    total_users: int
    regular_users: int
    doctors: int
    admins: int
    total_consultations: int
    pending_consultations: int
    replied_consultations: int
    health_habit_logs: int
    average_stress_score: Optional[float] = None
    latest_users: list[UserOut]
