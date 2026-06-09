
from sqlalchemy.orm import Session
from app.tables.conversation import Conversation   
from app.tables.message import Message             


class ConversationRepo:

    @staticmethod
    def create(db: Session, user_id: int, title: str) -> Conversation:
        conv = Conversation(user_id=user_id, title=title[:80])
        db.add(conv)
        db.commit()
        db.refresh(conv)
        return conv

    @staticmethod
    def get_by_id(db: Session, conv_id: int, user_id: int) -> Conversation | None:
        return (
            db.query(Conversation)
            .filter(Conversation.id == conv_id, Conversation.user_id == user_id)
            .first()
        )

    @staticmethod
    def get_all(db: Session, user_id: int) -> list[Conversation]:
        return (
            db.query(Conversation)
            .filter(Conversation.user_id == user_id)
            .order_by(Conversation.created_at.desc())
            .all()
        )

    @staticmethod
    def delete(db: Session, conv_id: int, user_id: int) -> bool:
        conv = ConversationRepo.get_by_id(db, conv_id, user_id)
        if not conv:
            return False
        db.delete(conv)
        db.commit()
        return True


class MessageRepo:

    @staticmethod
    def save(db: Session, conversation_id: int, role: str, content: str) -> Message:
        msg = Message(conversation_id=conversation_id, role=role, content=content)
        db.add(msg)
        db.commit()
        db.refresh(msg)
        return msg

    @staticmethod
    def get_history(db: Session, conversation_id: int) -> list[Message]:
        """Load all messages ordered by time — sent to Groq as context."""
        return (
            db.query(Message)
            .filter(Message.conversation_id == conversation_id)
            .order_by(Message.created_at.asc())
            .all()
        )