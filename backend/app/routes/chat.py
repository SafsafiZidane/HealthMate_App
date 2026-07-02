from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.config.db import get_db
from app.models.chat import ChatRequest, ChatResponse, ConversationOut, MessageOut
from app.services.chat_service import chat_with_history
from app.repository.chat import ConversationRepo, MessageRepo
from app.repository.users import JWTRepo
from app.repository.dependencies import get_current_standard_user
from app.tables.users import User

chatRouter = APIRouter(tags=["Chat"])

bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db)
) -> User:
    token = credentials.credentials
    payload = JWTRepo.verify_token(token)          # uses your existing method
    email = payload.get("sub")
    if not email:
        raise HTTPException(status_code=401, detail="Invalid token payload")
    user = db.query(User).filter(User.email == email).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user


@chatRouter.post("/chat", response_model=ChatResponse)
def chat(
    req: ChatRequest,
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    return chat_with_history(db, user, req.message, req.conversation_id)


@chatRouter.get("/conversations", response_model=list[ConversationOut])
def list_conversations(
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    return ConversationRepo.get_all(db, user.id)


@chatRouter.get("/conversations/{conv_id}/messages", response_model=list[MessageOut])
def get_messages(
    conv_id: int,
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    conv = ConversationRepo.get_by_id(db, conv_id, user.id)
    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")
    return MessageRepo.get_history(db, conv_id)


@chatRouter.delete("/conversations/{conv_id}", status_code=204)
def delete_conversation(
    conv_id: int,
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    if not ConversationRepo.delete(db, conv_id, user.id):
        raise HTTPException(status_code=404, detail="Conversation not found")