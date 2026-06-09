import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes.users import authRouter 
from app.config.db import engine,Base
from contextlib import asynccontextmanager
from fastapi import FastAPI
from app.tables import message, users, healthHabits,conversation
from app.routes.healthHabit import router as api_router
from app.routes.chat import chatRouter         





load_dotenv()

GROQ_API_KEY = os.getenv("GROQ_API_KEY")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    Base.metadata.create_all(bind=engine)

    
    yield
    # Cleanup on shutdown (if needed)

if not GROQ_API_KEY:
    raise ValueError("API key for Groq is missing. Please set the GROQ_API_KEY in the .env file.")


app = FastAPI(lifespan=lifespan)

app.include_router(authRouter) 
 # Include the health check router
app.include_router(api_router)
app.include_router(chatRouter, prefix="/api")


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