from sqlalchemy import Column, Integer, String
from app.config.db import Base
import datetime


class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    password = Column(String)
    first_name = Column(String, nullable=True)
    last_name = Column(String, nullable=True)
    created_at = Column(String, default=datetime.datetime.utcnow)
    updated_at = Column(String, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)