from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload
from app.config.db import get_db
from app.models.consultation import DoctorProfileBase
from app.repository.users import UserRepo, JWTRepo
from app.tables.users import User
from app.tables.doctor_profile import DoctorProfile
from app.tables.consultation import Consultation, ConsultationStatus
from app.tables.healthHabits import HealthHabits
from passlib.context import CryptContext
from app.models.users import (
    AdminCreateUser,
    AdminStats,
    AdminUpdateUser,
    ResponseSchema,
    Login,
    Register,
    TokenResponse,
    UserOut,
)
from app.tables.users import UserRole
from app.repository.dependencies import get_current_admin_user, get_current_user




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


@authRouter.get("/me", response_model=UserOut)
async def get_my_information(
    current_user: User = Depends(get_current_user),
):
    return current_user


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


def _ensure_unique_identity(db: Session, user_id: int | None, username: str | None, email: str | None) -> None:
    if username:
        existing_username = db.query(User).filter(User.username == username).first()
        if existing_username and existing_username.id != user_id:
            raise HTTPException(status_code=400, detail="Username is already used")
    if email:
        existing_email = db.query(User).filter(User.email == email).first()
        if existing_email and existing_email.id != user_id:
            raise HTTPException(status_code=400, detail="Email is already used")


def _upsert_doctor_profile(db: Session, user: User, profile_data: DoctorProfileBase | None) -> None:
    if user.role != UserRole.DOCTOR:
        if user.doctor_profile:
            db.delete(user.doctor_profile)
        return

    if profile_data is None:
        if user.doctor_profile is None:
            raise HTTPException(status_code=400, detail="Doctor profile is required for doctors")
        return

    payload = profile_data.model_dump()
    if user.doctor_profile:
        for key, value in payload.items():
            setattr(user.doctor_profile, key, value)
    else:
        db.add(DoctorProfile(doctor_id=user.id, **payload))


@authRouter.get("/admin/users", response_model=list[UserOut])
async def admin_list_users(
    role: UserRole | None = None,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
):
    query = db.query(User).options(joinedload(User.doctor_profile)).order_by(User.created_at.desc())
    if role:
        query = query.filter(User.role == role)
    return query.all()


@authRouter.get("/admin/users/{user_id}", response_model=UserOut)
async def admin_get_user(
    user_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
):
    user = db.query(User).options(joinedload(User.doctor_profile)).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@authRouter.patch("/admin/users/{user_id}", response_model=UserOut)
async def admin_update_user(
    user_id: int,
    request: AdminUpdateUser,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    _ensure_unique_identity(db, user.id, request.username, request.email)

    update_data = request.model_dump(exclude_unset=True, exclude={"password", "doctor_profile"})
    for key, value in update_data.items():
        setattr(user, key, value)

    if request.password:
        user.password = pwd_context.hash(request.password)

    try:
        _upsert_doctor_profile(db, user, request.doctor_profile)
        db.commit()
        db.refresh(user)
        return user
    except HTTPException:
        db.rollback()
        raise
    except Exception as e:
        db.rollback()
        print(f"Admin update user error: {str(e)}")
        raise HTTPException(status_code=500, detail="An error occurred while updating the user")


@authRouter.delete("/admin/users/{user_id}")
async def admin_delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
) -> ResponseSchema:
    if admin.id == user_id:
        raise HTTPException(status_code=400, detail="Administrators cannot delete their own account")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    db.delete(user)
    db.commit()
    return ResponseSchema(code="200", status="success", message="User deleted successfully")


@authRouter.get("/admin/doctors", response_model=list[UserOut])
async def admin_list_doctors(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
):
    return (
        db.query(User)
        .options(joinedload(User.doctor_profile))
        .filter(User.role == UserRole.DOCTOR)
        .order_by(User.created_at.desc())
        .all()
    )


@authRouter.patch("/admin/doctors/{doctor_id}/profile")
async def admin_update_doctor_profile(
    doctor_id: int,
    request: DoctorProfileBase,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
) -> ResponseSchema:
    doctor = db.query(User).filter(User.id == doctor_id, User.role == UserRole.DOCTOR).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")

    _upsert_doctor_profile(db, doctor, request)
    db.commit()
    return ResponseSchema(code="200", status="success", message="Doctor profile updated successfully")


@authRouter.delete("/admin/doctors/{doctor_id}")
async def admin_delete_doctor(
    doctor_id: int,
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
) -> ResponseSchema:
    doctor = db.query(User).filter(User.id == doctor_id, User.role == UserRole.DOCTOR).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")

    db.delete(doctor)
    db.commit()
    return ResponseSchema(code="200", status="success", message="Doctor deleted successfully")


@authRouter.get("/admin/statistics", response_model=AdminStats)
async def admin_statistics(
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin_user),
):
    total_users = db.query(func.count(User.id)).scalar() or 0
    regular_users = db.query(func.count(User.id)).filter(User.role == UserRole.USER).scalar() or 0
    doctors = db.query(func.count(User.id)).filter(User.role == UserRole.DOCTOR).scalar() or 0
    admins = db.query(func.count(User.id)).filter(User.role == UserRole.ADMIN).scalar() or 0
    total_consultations = db.query(func.count(Consultation.id)).scalar() or 0
    pending_consultations = (
        db.query(func.count(Consultation.id))
        .filter(Consultation.status == ConsultationStatus.PENDING)
        .scalar()
        or 0
    )
    replied_consultations = (
        db.query(func.count(Consultation.id))
        .filter(Consultation.status == ConsultationStatus.REPLIED)
        .scalar()
        or 0
    )
    health_habit_logs = db.query(func.count(HealthHabits.id)).scalar() or 0
    average_stress_score = db.query(func.avg(HealthHabits.stress_score)).scalar()
    latest_users = (
        db.query(User)
        .options(joinedload(User.doctor_profile))
        .order_by(User.created_at.desc())
        .limit(5)
        .all()
    )

    return AdminStats(
        total_users=total_users,
        regular_users=regular_users,
        doctors=doctors,
        admins=admins,
        total_consultations=total_consultations,
        pending_consultations=pending_consultations,
        replied_consultations=replied_consultations,
        health_habit_logs=health_habit_logs,
        average_stress_score=round(float(average_stress_score), 2) if average_stress_score is not None else None,
        latest_users=latest_users,
    )
