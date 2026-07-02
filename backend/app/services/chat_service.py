import os
from groq import Groq
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.repository.chat import ConversationRepo, MessageRepo
from app.tables.users import User

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
groq_client = Groq(api_key=GROQ_API_KEY)

SYSTEM_PROMPT = """You are a specialized nutrition assistant. You only answer questions related to:
- Nutrition, diet, healthy eating, meal planning, hydration, calories, macronutrients, micronutrients, supplements, and food habits
- Weight loss or weight gain when the answer is based on nutrition and healthy lifestyle behavior
- Exercise only when it directly supports a nutrition or weight-management question

If the user asks about anything outside nutrition, politely decline and redirect them to nutrition-related topics.
Never provide definitive medical diagnoses. Always recommend consulting a qualified healthcare professional for personal medical advice."""

OFF_TOPIC_NUTRITION_MESSAGE = (
    "I can only help with nutrition, diet, meal planning, supplements, hydration, "
    "and healthy weight-management questions. Please ask me something related to nutrition."
)

NUTRITION_KEYWORDS = {
    "nutrition",
    "diet",
    "meal",
    "food",
    "eat",
    "eating",
    "calorie",
    "calories",
    "protein",
    "carb",
    "carbs",
    "fat",
    "fiber",
    "vitamin",
    "mineral",
    "supplement",
    "hydration",
    "water",
    "weight",
    "lose weight",
    "gain weight",
    "breakfast",
    "lunch",
    "dinner",
    "snack",
    "recipe",
    "macros",
    "micronutrients",
    "vegetarian",
    "vegan",
    "keto",
}


def has_nutrition_keyword(message: str) -> bool:
    normalized = message.lower()
    return any(keyword in normalized for keyword in NUTRITION_KEYWORDS)


def is_nutrition_related(message: str) -> bool:
    """
    Quick classification check to block non-nutrition queries before hitting the main pipeline.
    """
    if has_nutrition_keyword(message):
        return True

    classification_prompt = (
        "You are a strict text classifier. Determine if the following user input is related to nutrition, "
        "diet, meals, food, supplements, hydration, calories, macronutrients, micronutrients, or healthy "
        "weight management.\n"
        "Respond with EXACTLY 'YES' if it is related, or 'NO' if it is not. Do not include any other text.\n\n"
        f"User Input: \"{message}\"\n"
        "Classification:"
    )
    
    try:
        completion = groq_client.chat.completions.create(
            model="llama-3.1-8b-instant",
            messages=[{"role": "user", "content": classification_prompt}],
            temperature=0.0,
            max_tokens=3,
        )
        decision = completion.choices[0].message.content.strip().upper()
        return "YES" in decision
    except Exception:
        return False

def chat_with_history(db: Session, user: User, message: str, conversation_id: int | None) -> dict:
    # ── 1. Get or create conversation ─────────────────────
    if conversation_id:
        conv = ConversationRepo.get_by_id(db, conversation_id, user.id)
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
    else:
        conv = ConversationRepo.create(db, user_id=user.id, title=message[:50]) # limit title length

    # ── 2. Save user message to DB ─────────────────────────
    MessageRepo.save(db, conv.id, role="user", content=message)

    if not is_nutrition_related(message):
        MessageRepo.save(db, conv.id, role="assistant", content=OFF_TOPIC_NUTRITION_MESSAGE)
        return {"conversation_id": conv.id, "response": OFF_TOPIC_NUTRITION_MESSAGE}

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
