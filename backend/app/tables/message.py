from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.config.db import Base
import datetime


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)

    conversation_id = Column(
        Integer,
        ForeignKey("conversations.id")
    )

    role = Column(String)
    content = Column(String)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    conversation = relationship(
        "Conversation",
        back_populates="messages"
    )