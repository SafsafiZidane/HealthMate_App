from datetime import datetime
from typing import Optional
from pydantic import BaseModel
from app.tables.consultation import ConsultationStatus


class DoctorProfileBase(BaseModel):
    specialty: str
    experience_years: int
    bio: Optional[str] = None
    clinic_address: Optional[str] = None


class DoctorProfileOut(DoctorProfileBase):
    id: int
    doctor_id: int

    class Config:
        from_attributes = True


class DoctorOut(BaseModel):
    id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: str
    email: str
    doctor_profile: Optional[DoctorProfileOut] = None

    class Config:
        from_attributes = True


class PatientOut(BaseModel):
    id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    username: str
    email: str

    class Config:
        from_attributes = True


class ConsultationCreate(BaseModel):
    doctor_id: int
    condition_description: str


class ConsultationReply(BaseModel):
    doctor_reply: str


class ConsultationOut(BaseModel):
    id: int
    user_id: int
    doctor_id: int
    condition_description: str
    doctor_reply: Optional[str] = None
    status: ConsultationStatus
    created_at: datetime
    replied_at: Optional[datetime] = None
    user: Optional[PatientOut] = None
    doctor: Optional[DoctorOut] = None

    class Config:
        from_attributes = True
