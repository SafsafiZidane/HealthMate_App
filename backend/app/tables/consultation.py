import datetime
import enum
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from app.config.db import Base


class ConsultationStatus(str, enum.Enum):
    PENDING = "pending"
    REPLIED = "replied"


class Consultation(Base):
    __tablename__ = "consultations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    condition_description = Column(Text, nullable=False)
    doctor_reply = Column(Text, nullable=True)
    status = Column(SQLEnum(ConsultationStatus), default=ConsultationStatus.PENDING, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    replied_at = Column(DateTime, nullable=True)

    user = relationship("User", foreign_keys=[user_id], back_populates="consultation_requests")
    doctor = relationship("User", foreign_keys=[doctor_id], back_populates="doctor_consultations")
