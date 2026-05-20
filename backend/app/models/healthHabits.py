from pydantic import BaseModel


class HealthHabitsInput(BaseModel):
    sleep_hours: float
    sleep_quality: float
    caffeine_mg: float
    exercise_min: float
    mood_score: float
    social_interaction: float
    water_liters: float
    meal_regularity: float
    junk_food: float
    work_hours: float
    screen_time_h: float
    mindfulness: float


class StressPredictionOutput(BaseModel):
    predicted_stress_score: float
    stress_level: str