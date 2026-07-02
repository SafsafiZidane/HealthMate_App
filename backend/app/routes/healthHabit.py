from fastapi import APIRouter, HTTPException, Depends 
from sqlalchemy.orm import Session
from app.config.db import get_db
from app.models.healthHabits import BMIPlanInput, BMIPlanOutput, HealthHabitsInput, StressPredictionOutput
from app.repository.dependencies import get_current_standard_user
from app.services.external_health_api import fetch_exercise_recommendations, fetch_nutrition_recommendations
from datetime import datetime
from app.repository.healthHabits import HealthHabitsRepo
from app.tables.users import User
from app.repository.users import UserRepo
from app.tables.healthHabits import HealthHabits

router = APIRouter(dependencies=[Depends(get_current_standard_user)])


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


def estimate_daily_calories(
    goal: str,
    weight_kg: float,
    height_cm: float,
    age: int | None = None,
    sex: str | None = None,
    activity_level: str | None = None,
) -> int:
    activity_multipliers = {
        "sedentary": 1.2,
        "light": 1.375,
        "moderate": 1.55,
        "active": 1.725,
        "very_active": 1.9,
    }
    age = age or 30
    sex_adjustment = 5 if sex == "male" else -161 if sex == "female" else -78
    bmr = (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + sex_adjustment
    maintenance = bmr * activity_multipliers.get(activity_level or "light", 1.375)
    target = maintenance - 400 if goal == "lose" else maintenance + 300
    minimum = 1200 if sex == "female" else 1500 if sex == "male" else 1300
    return round(max(minimum, target))


def build_bmi_plan(
    goal: str,
    bmi_category: str,
    diet: str | None = None,
    exercise_focus: str | None = None,
    daily_calorie_target: int | None = None,
) -> dict[str, list[str]]:
    common_recommendations = [
        "Track weight once per week, not every day.",
        "Drink 2 to 3 liters of water daily unless your doctor told you otherwise.",
        "Sleep 7 to 9 hours per night to support recovery and appetite control.",
        "Target protein at each meal to protect muscle while weight changes.",
        "Ask a doctor or dietitian before starting if you have diabetes, heart disease, kidney disease, or an eating disorder history.",
    ]

    if goal == "lose":
        default_nutrition_plan = [
            "Use a moderate calorie deficit: keep meals filling with lean protein, vegetables, fruit, and whole grains.",
            "Breakfast idea: Greek yogurt or eggs with fruit and oats.",
            "Lunch idea: chicken, tuna, tofu, beans, or lentils with salad and rice, potatoes, or whole-grain bread.",
            "Dinner idea: fish, turkey, eggs, legumes, or tofu with cooked vegetables and a measured portion of carbs.",
            "Snack idea: fruit, yogurt, cottage cheese, boiled eggs, or a small handful of nuts.",
            "Limit liquid calories, fried food, pastries, and oversized portions to occasional planned choices.",
        ]
        default_exercise_plan = [
            "Weekly target: 150 to 300 minutes of moderate cardio such as brisk walking, cycling, swimming, or jogging.",
            "Strength plan: 2 to 3 full-body sessions weekly with squats or leg press, hip hinge, rows, presses, and core work.",
            "Beginner session: 5 minute warm-up, 3 rounds of 8 to 12 reps for 5 exercises, then 10 to 20 minutes easy cardio.",
            "Daily movement: aim for 7,000 to 10,000 steps or add 10 minute walks after meals.",
            "Progress rule: increase time, repetitions, or load slightly every 1 to 2 weeks if recovery is good.",
        ]
    else:
        default_nutrition_plan = [
            "Use a small calorie surplus with 3 main meals and 1 to 2 snacks daily.",
            "Breakfast idea: oats with milk, peanut butter, banana, and yogurt or eggs.",
            "Lunch idea: rice, pasta, potatoes, or bread with chicken, fish, eggs, beans, lentils, or tofu plus olive oil.",
            "Dinner idea: protein plus a large carbohydrate serving and vegetables cooked with healthy fats.",
            "Snack idea: smoothies, nuts, dates, cheese, yogurt, hummus, sandwiches, or avocado toast.",
            "Increase portions gradually so gain is steady, digestion is comfortable, and most gain supports muscle.",
        ]
        default_exercise_plan = [
            "Strength plan: train 3 to 4 days weekly and record sets, reps, and weights.",
            "Focus on compound movements: squat or leg press, deadlift or hip hinge, bench or push-ups, rows, overhead press, lunges, and pull-downs.",
            "Muscle gain target: 3 to 5 sets of 6 to 12 reps for main lifts, stopping 1 to 3 reps before failure.",
            "Keep cardio light to moderate, 1 to 2 sessions weekly, for heart health without making eating harder.",
            "Recovery rule: sleep well and rest each muscle group at least 48 hours before hard training again.",
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

    try:
        nutrition_plan, target_calories = fetch_nutrition_recommendations(
            goal, diet=diet, daily_calorie_target=daily_calorie_target
        )
        recommendations.insert(0, f"Estimated daily target: {target_calories} kcal.")
    except HTTPException:
        nutrition_plan = default_nutrition_plan
        recommendations.append(
            "Unable to fetch external nutrition guidance. Using local healthy eating recommendations instead."
        )
        if daily_calorie_target:
            recommendations.insert(0, f"Estimated daily target: {daily_calorie_target} kcal.")

    try:
        exercise_plan = fetch_exercise_recommendations(
            goal, focus_area=exercise_focus, available_minutes=30
        )
    except HTTPException:
        exercise_plan = default_exercise_plan
        recommendations.append(
            "Unable to fetch external exercise guidance. Using local exercise recommendations instead."
        )

    return {
        "nutrition_plan": nutrition_plan,
        "exercise_plan": exercise_plan,
        "recommendations": recommendations,
    }



@router.post("/predict", response_model=StressPredictionOutput)
async def predict_stress(
    habits: HealthHabitsInput, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_standard_user)
):
    try:
        data = habits.dict()
        score = calculate_stress(data)
        level = get_stress_level(score)
        user_email = current_user.email
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
    if plan_input.age is not None and (plan_input.age < 13 or plan_input.age > 100):
        raise HTTPException(status_code=400, detail="age must be between 13 and 100")

    bmi = calculate_bmi(plan_input.weight_kg, plan_input.height_cm)
    bmi_category = get_bmi_category(bmi)
    daily_calorie_target = plan_input.daily_calorie_target or estimate_daily_calories(
        plan_input.goal,
        plan_input.weight_kg,
        plan_input.height_cm,
        age=plan_input.age,
        sex=plan_input.sex,
        activity_level=plan_input.activity_level,
    )
    plan = build_bmi_plan(
        plan_input.goal,
        bmi_category,
        diet=plan_input.diet,
        exercise_focus=plan_input.exercise_focus,
        daily_calorie_target=daily_calorie_target,
    )

    return BMIPlanOutput(
        bmi=bmi,
        bmi_category=bmi_category,
        goal=plan_input.goal,
        target_weight_range_kg=get_target_weight_range(plan_input.height_cm),
        nutrition_plan=plan["nutrition_plan"],
        exercise_plan=plan["exercise_plan"],
        recommendations=plan["recommendations"],
    )
