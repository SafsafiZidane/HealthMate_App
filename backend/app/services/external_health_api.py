import os
import requests
from fastapi import HTTPException

SPOONACULAR_API_KEY = os.getenv("SPOONACULAR_API_KEY")
SPOONACULAR_BASE_URL = "https://api.spoonacular.com"
WGER_BASE_URL = "https://wger.de/api/v2"


def fetch_nutrition_recommendations(
    goal: str,
    diet: str | None = None,
    daily_calorie_target: int | None = None,
) -> tuple[list[str], int]:
    if not SPOONACULAR_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Missing SPOONACULAR_API_KEY environment variable for external nutrition recommendations.",
        )

    if daily_calorie_target is None:
        daily_calorie_target = 1800 if goal == "lose" else 2400

    params = {
        "timeFrame": "day",
        "targetCalories": daily_calorie_target,
        "apiKey": SPOONACULAR_API_KEY,
    }
    if diet:
        params["diet"] = diet

    try:
        response = requests.get(
            f"{SPOONACULAR_BASE_URL}/mealplanner/generate",
            params=params,
            timeout=10,
        )
        response.raise_for_status()
        payload = response.json()
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Nutrition API request failed: {str(exc)}",
        )

    meals = payload.get("meals", [])
    nutrients = payload.get("nutrients", {})
    recommendations: list[str] = []

    if meals:
        recommendations.append("Meal suggestions:")
        for meal in meals:
            title = meal.get("title", "Meal")
            ready = meal.get("readyInMinutes")
            servings = meal.get("servings")
            recommendations.append(
                f"{title} - {ready} min prep, serves {servings}."
            )
        recommendations.append(
            "Choose balanced meals with lean protein, whole grains, vegetables, and healthy fats."
        )
        recommendations.append(
            f"Daily target: {daily_calorie_target} kcal, protein: {nutrients.get('protein','N/A')}g, carbs: {nutrients.get('carbohydrates','N/A')}g, fat: {nutrients.get('fat','N/A')}g."
        )
    else:
        recommendations = [
            "Eat three balanced meals with vegetables, lean protein, and whole grains.",
            "Choose healthy snacks like fruit, yogurt, nuts, and hummus.",
            "Stay hydrated and keep portion sizes steady throughout the day.",
        ]

    return recommendations, daily_calorie_target


def fetch_exercise_recommendations(
    goal: str,
    focus_area: str | None = None,
    available_minutes: int | None = 30,
) -> list[str]:
    try:
        response = requests.get(
            f"{WGER_BASE_URL}/exerciseinfo/",
            params={"language": 2, "limit": 12},
            timeout=10,
        )
        response.raise_for_status()
        payload = response.json()
    except requests.RequestException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Exercise API request failed: {str(exc)}",
        )

    results = payload.get("results", [])
    recommendations: list[str] = []

    if goal == "lose":
        recommendations.append(
            "Aim for at least 150 minutes of moderate cardio each week and combine it with strength-focused movement."
        )
    else:
        recommendations.append(
            "Prioritize strength training 3 to 4 times per week and increase load gradually."
        )

    if available_minutes:
        recommendations.append(
            f"Schedule workouts of roughly {available_minutes} minutes, adjusting intensity to your fitness level."
        )

    for exercise in results:
        if len(recommendations) >= 7:
            break

        name = exercise.get("name", "Exercise")
        description = exercise.get("description", "").replace("<p>", "").replace("</p>", "").strip()
        if focus_area and focus_area.lower() not in name.lower() and focus_area.lower() not in description.lower():
            continue

        text = name
        if description:
            text += f": {description}"
        recommendations.append(text)

    if len(recommendations) < 5:
        for exercise in results:
            if len(recommendations) >= 5:
                break
            name = exercise.get("name", "Exercise")
            description = exercise.get("description", "").replace("<p>", "").replace("</p>", "").strip()
            text = name
            if description:
                text += f": {description}"
            if text not in recommendations:
                recommendations.append(text)

    return recommendations
