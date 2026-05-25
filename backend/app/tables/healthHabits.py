from sqlalchemy import Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.config.db import Base
import datetime


class HealthHabits(Base):
    __tablename__ = "health_habits"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id")
    )

    sleep_hours = Column(Float)
    sleep_quality = Column(Float)
    caffeine_mg = Column(Float)
    exercise_min = Column(Float)
    mood_score = Column(Float)
    social_interaction = Column(Float)
    water_liters = Column(Float)
    meal_regularity = Column(Float)
    junk_food = Column(Float)
    work_hours = Column(Float)
    screen_time_h = Column(Float)
    mindfulness = Column(Float)


    stress_score = Column(Float, nullable=False)

    created_at = Column(
        DateTime,
        default=datetime.datetime.utcnow
    )

    user = relationship(
        "User",
        back_populates="health_habits"
    )