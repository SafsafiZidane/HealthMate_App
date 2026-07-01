from fastapi import APIRouter, HTTPException, Depends 
from sqlalchemy.orm import Session
from app.config.db import get_db
from app.models.healthHabits import BMIPlanInput, BMIPlanOutput, HealthHabitsInput, StressPredictionOutput
from app.repository.dependencies import get_current_user
from datetime import datetime
from app.repository.healthHabits import HealthHabitsRepo
from app.tables.users import User
from app.repository.users import UserRepo
from app.tables.healthHabits import HealthHabits

router = APIRouter(dependencies=[Depends(get_current_user)])


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


def calculate_bmi(weight_kg: float, height_cm: float) -> float:
    height_m = height_cm / 100
    return round(weight_kg / (height_m ** 2), 2)


def get_bmi_category(bmi: float) -> str:
    if bmi < 18.5:
        return "Underweight"
    if bmi < 25:
        return "Normal"
    if bmi < 30:
        return "Overweight"
    return "Obese"


def get_target_weight_range(height_cm: float) -> str:
    height_m = height_cm / 100
    min_weight = 18.5 * (height_m ** 2)
    max_weight = 24.9 * (height_m ** 2)
    return f"{round(min_weight, 1)} - {round(max_weight, 1)}"


def build_bmi_plan(goal: str, bmi_category: str) -> dict[str, list[str]]:
    common_recommendations = [
        "Track weight once per week, not every day.",
        "Drink 2 to 3 liters of water daily unless your doctor told you otherwise.",
        "Sleep 7 to 9 hours per night to support recovery and appetite control.",
        "Ask a doctor or dietitian before starting if you have diabetes, heart disease, kidney disease, or an eating disorder history.",
    ]

    if goal == "lose":
        nutrition_plan = [
            "Create a small calorie deficit by reducing sugary drinks, fried food, and oversized portions.",
            "Eat protein with each meal: eggs, chicken, fish, yogurt, beans, lentils, or tofu.",
            "Fill half the plate with vegetables and fruit, one quarter with protein, and one quarter with whole grains or potatoes.",
            "Choose healthy snacks like fruit, yogurt, nuts in small portions, or boiled eggs.",
        ]
        exercise_plan = [
            "Do 150 to 300 minutes of moderate cardio weekly, such as brisk walking, cycling, or swimming.",
            "Add strength training 2 to 3 days per week for full body muscles.",
            "Start with 20 to 30 minutes per session if you are inactive, then increase gradually.",
            "Add daily movement: stairs, walking after meals, and short activity breaks.",
        ]
    else:
        nutrition_plan = [
            "Create a small calorie surplus with 3 main meals and 1 to 2 snacks daily.",
            "Prioritize protein with each meal: eggs, chicken, fish, dairy, beans, lentils, or tofu.",
            "Add calorie-dense healthy foods like olive oil, avocado, nuts, peanut butter, rice, pasta, oats, and smoothies.",
            "Increase portions gradually so weight gain is steady and comfortable.",
        ]
        exercise_plan = [
            "Do strength training 3 to 4 days per week with progressive overload.",
            "Focus on compound movements: squats, deadlifts, presses, rows, lunges, and pull movements.",
            "Keep cardio light to moderate, 1 to 2 sessions weekly, for heart health.",
            "Rest each muscle group at least 48 hours before training it hard again.",
        ]

    recommendations = common_recommendations
    if goal == "lose" and bmi_category == "Underweight":
        recommendations = [
            "Your BMI is already under the normal range, so weight loss is not recommended without medical supervision.",
            *common_recommendations,
        ]
    elif goal == "gain" and bmi_category in ["Overweight", "Obese"]:
        recommendations = [
            "Your BMI is above the normal range, so focus on strength, nutrition quality, and medical advice before gaining more weight.",
            *common_recommendations,
        ]

    return {
        "nutrition_plan": nutrition_plan,
        "exercise_plan": exercise_plan,
        "recommendations": recommendations,
    }



@router.post("/predict", response_model=StressPredictionOutput)
async def predict_stress(
    habits: HealthHabitsInput, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    try:
        data = habits.dict()
        score = calculate_stress(data)
        level = get_stress_level(score)
        user_email = current_user["sub"]
        db_user = UserRepo.find_by_email(db, User, user_email)
        # 1. Map incoming Pydantic input to your SQLAlchemy Database Table format
        new_habit_record = HealthHabits(
            user_id=db_user.id, # Now this works perfectly
            sleep_hours=habits.sleep_hours,
            sleep_quality=habits.sleep_quality,
            caffeine_mg=habits.caffeine_mg,
            exercise_min=habits.exercise_min,
            mood_score=habits.mood_score,
            social_interaction=habits.social_interaction,
            water_liters=habits.water_liters,
            meal_regularity=habits.meal_regularity,
            junk_food=habits.junk_food,
            work_hours=habits.work_hours,
            screen_time_h=habits.screen_time_h,
            mindfulness=habits.mindfulness,
            stress_score=score, # Saved directly to your history
            created_at=datetime.utcnow()
        )

        # 2. Use your inherited BaseRepo method to save to database
        HealthHabitsRepo.insert(db, new_habit_record)

        return StressPredictionOutput(
            predicted_stress_score=score,
            stress_level=level
        )

    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail=f"Prediction error: {str(e)}"
        )


@router.post("/bmi-plan", response_model=BMIPlanOutput)
async def recommend_bmi_plan(plan_input: BMIPlanInput):
    if plan_input.height_cm <= 0:
        raise HTTPException(status_code=400, detail="height_cm must be greater than 0")
    if plan_input.weight_kg <= 0:
        raise HTTPException(status_code=400, detail="weight_kg must be greater than 0")
    if plan_input.height_cm < 80 or plan_input.height_cm > 250:
        raise HTTPException(status_code=400, detail="height_cm must be between 80 and 250")
    if plan_input.weight_kg < 20 or plan_input.weight_kg > 350:
        raise HTTPException(status_code=400, detail="weight_kg must be between 20 and 350")

    bmi = calculate_bmi(plan_input.weight_kg, plan_input.height_cm)
    bmi_category = get_bmi_category(bmi)
    plan = build_bmi_plan(plan_input.goal, bmi_category)

    return BMIPlanOutput(
        bmi=bmi,
        bmi_category=bmi_category,
        goal=plan_input.goal,
        target_weight_range_kg=get_target_weight_range(plan_input.height_cm),
        nutrition_plan=plan["nutrition_plan"],
        exercise_plan=plan["exercise_plan"],
        recommendations=plan["recommendations"],
    )
