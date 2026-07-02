from typing import Literal

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


class BMIPlanInput(BaseModel):
    height_cm: float
    weight_kg: float
    goal: Literal["lose", "gain"]
    age: int | None = None
    sex: Literal["male", "female"] | None = None
    activity_level: Literal["sedentary", "light", "moderate", "active", "very_active"] | None = None
    diet: str | None = None
    exercise_focus: str | None = None
    daily_calorie_target: int | None = None


class BMIPlanOutput(BaseModel):
    bmi: float
    bmi_category: str
    goal: str
    target_weight_range_kg: str
    nutrition_plan: list[str]
    exercise_plan: list[str]
    recommendations: list[str]
