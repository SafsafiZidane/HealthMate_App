from sqlalchemy import Column, Integer, String, DateTime, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.config.db import Base
import datetime
import enum

class UserRole(str, enum.Enum):
    USER = "user"
    ADMIN = "admin"
    DOCTOR = "doctor"

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)

    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)

    password = Column(String)

    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    role = Column(
        SQLEnum(UserRole), 
        default=UserRole.USER,  # Default new accounts to standard users
        nullable=False
    )

    created_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    updated_at = Column(
        DateTime,
        default=datetime.datetime.utcnow,
        onupdate=datetime.datetime.utcnow
    )

    conversations = relationship(
        "Conversation",
        back_populates="user",
        cascade="all, delete"
    )   

    health_habits = relationship(
        "HealthHabits",
        back_populates="user",
        cascade="all, delete"
    )

    doctor_profile = relationship(
        "DoctorProfile",
        back_populates="doctor",
        uselist=False,
        cascade="all, delete"
    )

    consultation_requests = relationship(
        "Consultation",
        foreign_keys="Consultation.user_id",
        back_populates="user",
        cascade="all, delete"
    )

    doctor_consultations = relationship(
        "Consultation",
        foreign_keys="Consultation.doctor_id",
        back_populates="doctor",
        cascade="all, delete"
    )
