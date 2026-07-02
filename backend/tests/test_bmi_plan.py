from fastapi import HTTPException

from app.routes import healthHabit
from app.routes.healthHabit import build_bmi_plan, estimate_daily_calories


def test_estimate_daily_calories_changes_by_goal():
    lose_target = estimate_daily_calories("lose", weight_kg=80, height_cm=175, age=30, sex="male")
    gain_target = estimate_daily_calories("gain", weight_kg=80, height_cm=175, age=30, sex="male")

    assert gain_target > lose_target


def test_local_bmi_plan_includes_calorie_target_when_external_services_unavailable(monkeypatch):
    def _raise_external_unavailable(*args, **kwargs):
        raise HTTPException(status_code=502, detail="external service unavailable")

    monkeypatch.setattr(healthHabit, "fetch_nutrition_recommendations", _raise_external_unavailable)
    monkeypatch.setattr(healthHabit, "fetch_exercise_recommendations", _raise_external_unavailable)

    plan = build_bmi_plan("lose", "Overweight", daily_calorie_target=1900)

    assert "Estimated daily target: 1900 kcal." in plan["recommendations"]
    assert any("calorie deficit" in item for item in plan["nutrition_plan"])
    assert any("150 to 300 minutes" in item for item in plan["exercise_plan"])
