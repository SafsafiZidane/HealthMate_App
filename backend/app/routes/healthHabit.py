from fastapi import APIRouter, HTTPException
from app.models.healthHabits import HealthHabitsInput, StressPredictionOutput

router = APIRouter()

# ─────────────────────────────────────────────
# Stress Formula
# ─────────────────────────────────────────────
def calculate_stress(data):

    stress = 0

    # ─────────────────────────────
    # Sleep duration (VERY IMPORTANT)
    # ─────────────────────────────
    sleep_penalty = max(0, (7 - data["sleep_hours"]) / 7)
    stress += 6.0 * (sleep_penalty ** 2)

    # Sleep quality
    stress += 2.0 * ((10 - data["sleep_quality"]) / 10)

    # Caffeine
    stress += 0.8 * (data["caffeine_mg"] / 400)

    # Exercise protection
    stress -= 1.0 * min(data["exercise_min"] / 60, 1)

    # Mood
    stress -= 0.8 * (data["mood_score"] / 10)

    # Social interaction
    stress -= 0.5 * (data["social_interaction"] / 10)

    # Hydration
    hydration_penalty = max(0, (2 - data["water_liters"]) / 2)
    stress += 1.5 * hydration_penalty

    # Meal regularity
    stress += 1.2 * ((10 - data["meal_regularity"]) / 10)

    # Junk food
    stress += 1.0 * (data["junk_food"] / 10)

    # Work overload
    work_penalty = max(0, (data["work_hours"] - 8) / 8)
    stress += 3.0 * (work_penalty ** 1.5)

    # Screen time
    stress += 0.5 * (data["screen_time_h"] / 10)

    # Mindfulness
    stress -= 0.7 * (data["mindfulness"] / 10)

    # Clamp
    stress = max(0, min(10, stress))

    return round(stress, 2)


# ─────────────────────────────────────────────
# Stress Level
# ─────────────────────────────────────────────
def get_stress_level(score: float):

    if score < 3:
        return "Low"

    elif score < 5:
        return "Moderate"

    elif score < 7:
        return "Elevated"

    elif score < 8.5:
        return "High"

    return "Critical"


# ─────────────────────────────────────────────
# API Route
# ─────────────────────────────────────────────
@router.post("/predict", response_model=StressPredictionOutput)
async def predict_stress(habits: HealthHabitsInput):

    try:
        data = habits.dict()

        score = calculate_stress(data)

        level = get_stress_level(score)

        return StressPredictionOutput(
            predicted_stress_score=score,
            stress_level=level
        )

    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Prediction error: {str(e)}"
        )