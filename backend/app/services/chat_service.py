import os
from groq import Groq
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.repository.chat import ConversationRepo, MessageRepo
from app.tables.users import User

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
groq_client = Groq(api_key=GROQ_API_KEY)

SYSTEM_PROMPT = """You are a specialized AI health assistant. You only answer questions related to:
- Medical conditions, symptoms, and diseases
- Nutrition, diet, and healthy eating
- Exercise, fitness, and physical wellness
- Mental health and emotional well-being
- Medications, supplements, and treatments
- Preventive care and healthy lifestyle habits
- Medical terminology and health education

If the user asks about anything unrelated to health, politely decline and redirect them to health-related topics.
Never provide definitive medical diagnoses. Always recommend consulting a qualified healthcare professional for personal medical advice."""


def is_health_related(message: str) -> bool:
    """
    Quick classification check to block non-health queries before hitting the main pipeline.
    """
    classification_prompt = (
        "You are a strict text classifier. Determine if the following user input is related to medicine, "
        "health, symptoms, fitness, nutrition, or mental well-being.\n"
        "Respond with EXACTLY 'YES' if it is related, or 'NO' if it is not. Do not include any other text.\n\n"
        f"User Input: \"{message}\"\n"
        "Classification:"
    )
    
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant", # Or a faster/cheaper model if available
            messages=[{"role": "user", "content": classification_prompt}],
            temperature=0.0,  # Deterministic response
            max_tokens=3,
        )
        decision = completion.choices[0].message.content.strip().upper()
        return "YES" in decision
    except Exception:
        # Fallback: if guardrail fails, let it pass to the main prompt or log it
        return True

def chat_with_history(db: Session, user: User, message: str, conversation_id: int | None) -> dict:
    # ── GUARDRAIL STEP ────────────────────────────────────
    if not is_health_related(message):
        # We reject immediately. We don't even create a conversation or save to DB.
        raise HTTPException(
            status_code=400, 
            detail="I can only assist you with health, medical, or wellness-related inquiries."
        )

    # ── 1. Get or create conversation ─────────────────────
    if conversation_id:
        conv = ConversationRepo.get_by_id(db, conversation_id, user.id)
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        conv = ConversationRepo.create(db, user_id=user.id, title=message[:50]) # limit title length

    # ── 2. Save user message to DB ─────────────────────────
    MessageRepo.save(db, conv.id, role="user", content=message)

    # ── 3. Load FULL history from DB ───────────────────────
    history = MessageRepo.get_history(db, conv.id)

    groq_messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    groq_messages += [{"role": m.role, "content": m.content} for m in history]

    # ── 4. Call Groq ───────────────────────────────────────
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=groq_messages,
            temperature=0.3, # Dropped to 0.3 for more factual, less hallucinated responses
            max_tokens=1024,
        )
        ai_response = completion.choices[0].message.content
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Groq API error: {str(e)}")

    # ── 5. Save assistant reply to DB ──────────────────────
    MessageRepo.save(db, conv.id, role="assistant", content=ai_response)

    return {"conversation_id": conv.id, "response": ai_response}