import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.users import authRouter

from app.config.db import engine,Base
from contextlib import asynccontextmanager
from fastapi import FastAPI
from pathlib import Path





load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")

# 1. Get the path to 'C:\Users\zidan\Desktop\projet_developement\backend\app'
CURRENT_DIR = Path(__file__).resolve().parent

# 2. Hardcode the jump up to 'backend' directory explicitly
BACKEND_DIR = CURRENT_DIR.parent 

MODEL_PATH = BACKEND_DIR / "artifacts" / "stress_model_full.pt"
SCALER_PATH = BACKEND_DIR / "artifacts" / "scaler.pkl"

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    Base.metadata.create_all(bind=engine)

    try:
        
        print("⏳ Loading machine learning models and components...")
        predictor_service.load_artifacts(
            model_path = MODEL_PATH,
            scaler_path = SCALER_PATH
        )
        print("✅ Models and scalers loaded successfully!")
    except Exception as e:
        print(f"❌ Critical initialization failure: {e}")
        raise RuntimeError(f"Startup stopped: {e}")
    
    yield
    # Cleanup on shutdown (if needed)

if not GROQ_API_KEY:
    raise ValueError("API key for Groq is missing. Please set the GROQ_API_KEY in the .env file.")


app = FastAPI(lifespan=lifespan)

app.include_router(authRouter) 
 # Include the health check router
app.include_router(api_router)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)