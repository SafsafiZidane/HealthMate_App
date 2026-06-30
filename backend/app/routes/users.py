from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.config.db import get_db
from app.repository.users import UserRepo, JWTRepo
from app.tables.users import User
from app.tables.doctor_profile import DoctorProfile
from passlib.context import CryptContext
from app.models.users import ResponseSchema, Login, Register, TokenResponse, AdminCreateUser
from app.tables.users import UserRole
from app.repository.dependencies import get_current_admin_user




authRouter = APIRouter(
    tags=["Authentication"]
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@authRouter.post("/register")
async def register(request: Register, db: Session = Depends(get_db)) -> ResponseSchema:
    
    try:
        hashed_password = pwd_context.hash(request.password)
        _user = User(
            first_name = request.first_name,
            last_name = request.last_name,
            username = request.username,
            email = request.email,
            password = hashed_password,
             role = UserRole.USER )
        UserRepo.insert(db, _user)
        return ResponseSchema(code="200", status="success", message="User registered successfully")
    except Exception as e:
        print(f"Registration error: {str(e)}")
        return ResponseSchema(code="500", status="error", message="An error occurred during registration")

@authRouter.post("/login")
async def login(request: Login, db: Session = Depends(get_db)) -> ResponseSchema:
    try:
        _user = UserRepo.find_by_email(db,User, request.email)
        if not _user or not pwd_context.verify(request.password, _user.password):
            return ResponseSchema(code="401", status="error", message="Invalid email or password")
        
        token = JWTRepo.create_access_token(data={"sub": _user.email})
        return ResponseSchema(code="200", status="success", message="Login successful", result=TokenResponse(access_token=token, token_type="bearer"))
    except Exception as e:
        print(f"Login error: {str(e)}")
        return ResponseSchema(code="500", status="error", message="An error occurred during login") 


@authRouter.post("/admin/users")
async def admin_create_user(
    request: AdminCreateUser,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user)
) -> ResponseSchema:
    try:
        if request.role == UserRole.DOCTOR and request.doctor_profile is None:
            return ResponseSchema(
                code="400",
                status="error",
                message="Doctor profile is required when creating a doctor"
            )

        hashed_password = pwd_context.hash(request.password)
        user = User(
            first_name=request.first_name,
            last_name=request.last_name,
            username=request.username,
            email=request.email,
            password=hashed_password,
            role=request.role
        )
        db.add(user)
        db.flush()

        if request.role == UserRole.DOCTOR:
            profile_data = request.doctor_profile.model_dump()
            db.add(DoctorProfile(doctor_id=user.id, **profile_data))

        db.commit()
        db.refresh(user)
        return ResponseSchema(code="200", status="success", message="User created successfully")
    except Exception as e:
        db.rollback()
        print(f"Admin create user error: {str(e)}")
        return ResponseSchema(code="500", status="error", message="An error occurred while creating the user")
    
