from sqlalchemy import Column, Integer, String, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.config.db import Base


class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"

    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    specialty = Column(String, nullable=False)
    experience_years = Column(Integer, nullable=False, default=0)
    bio = Column(Text, nullable=True)
    clinic_address = Column(String, nullable=True)

    doctor = relationship("User", back_populates="doctor_profile")
