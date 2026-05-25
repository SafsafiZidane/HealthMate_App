from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, date, timedelta
from typing import List, Optional
from app.tables.healthHabits import HealthHabits # Assuming this is your SQLAlchemy model name
from app.repository.users import BaseRepo # Adjust path to your BaseRepo file

class HealthHabitsRepo(BaseRepo):

    @staticmethod
    def get_by_id(db: Session, habit_id: int) -> Optional[HealthHabits]:
        """Fetch a specific log entry by its primary key ID."""
        return db.query(HealthHabits).filter(HealthHabits.id == habit_id).first()

    @staticmethod
    def get_user_log_for_date(db: Session, user_id: int, target_date: date) -> Optional[HealthHabits]:
        """
        Fetches the habit log for a specific user on a precise calendar date.
        Essential for showing 'Today's Progress' on the dashboard.
        """
        return db.query(HealthHabits).filter(
            HealthHabits.user_id == user_id,
            func.date(HealthHabits.created_at) == target_date
        ).first()

    @staticmethod
    def get_user_history_range(db: Session, user_id: int, start_date: date, end_date: date) -> List[HealthHabits]:
        """
        Fetches all logs between two dates.
        Perfect for rendering weekly/monthly charts like 'Sleep Trends'.
        """
        return db.query(HealthHabits).filter(
            HealthHabits.user_id == user_id,
            func.date(HealthHabits.created_at) >= start_date,
            func.date(HealthHabits.created_at) <= end_date
        ).order_by(HealthHabits.created_at.asc()).all()

    @staticmethod
    def update_daily_metrics(db: Session, user_id: int, target_date: date, update_data: dict) -> Optional[HealthHabits]:
        """
        Updates fields dynamically if a user logs water multiple times a day.
        If a entry doesn't exist for today, you should insert a new one instead.
        """
        existing_log = db.query(HealthHabits).filter(
            HealthHabits.user_id == user_id,
            func.date(HealthHabits.created_at) == target_date
        ).first()

        if existing_log:
            for key, value in update_data.items():
                if hasattr(existing_log, key) and value is not None:
                    setattr(existing_log, key, value)
            db.commit()
            db.refresh(existing_log)
        return existing_log