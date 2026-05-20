from fastapi import APIRouter, HTTPException
from app.config.ml_config import HealthHabitsInput, StressPredictionOutput
from app.services.predictor import predictor_service

router = APIRouter()

@router.post("/predict", response_model=StressPredictionOutput)
async def predict_stress(habits: HealthHabitsInput):
    try:
        score, level = predictor_service.predict(habits)
        return StressPredictionOutput(
            predicted_stress_score=score,
            stress_level=level
        )
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Prediction error: {str(e)}")