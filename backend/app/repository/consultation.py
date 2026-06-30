import datetime
from sqlalchemy.orm import Session, joinedload
from app.tables.consultation import Consultation, ConsultationStatus
from app.tables.doctor_profile import DoctorProfile
from app.tables.users import User, UserRole


class DoctorRepo:
    @staticmethod
    def list_doctors(db: Session) -> list[User]:
        return (
            db.query(User)
            .options(joinedload(User.doctor_profile))
            .filter(User.role == UserRole.DOCTOR)
            .order_by(User.first_name.asc(), User.last_name.asc())
            .all()
        )

    @staticmethod
    def get_doctor(db: Session, doctor_id: int) -> User | None:
        return (
            db.query(User)
            .options(joinedload(User.doctor_profile))
            .filter(User.id == doctor_id, User.role == UserRole.DOCTOR)
            .first()
        )


class ConsultationRepo:
    @staticmethod
    def create(db: Session, user_id: int, doctor_id: int, condition_description: str) -> Consultation:
        consultation = Consultation(
            user_id=user_id,
            doctor_id=doctor_id,
            condition_description=condition_description
        )
        db.add(consultation)
        db.commit()
        db.refresh(consultation)
        return consultation

    @staticmethod
    def get_for_user(db: Session, consultation_id: int, user_id: int) -> Consultation | None:
        return (
            db.query(Consultation)
            .filter(Consultation.id == consultation_id, Consultation.user_id == user_id)
            .first()
        )

    @staticmethod
    def get_for_doctor(db: Session, consultation_id: int, doctor_id: int) -> Consultation | None:
        return (
            db.query(Consultation)
            .filter(Consultation.id == consultation_id, Consultation.doctor_id == doctor_id)
            .first()
        )

    @staticmethod
    def list_for_user(db: Session, user_id: int) -> list[Consultation]:
        return (
            db.query(Consultation)
            .filter(Consultation.user_id == user_id)
            .order_by(Consultation.created_at.desc())
            .all()
        )

    @staticmethod
    def list_for_doctor(db: Session, doctor_id: int) -> list[Consultation]:
        return (
            db.query(Consultation)
            .filter(Consultation.doctor_id == doctor_id)
            .order_by(Consultation.created_at.desc())
            .all()
        )

    @staticmethod
    def reply(db: Session, consultation: Consultation, doctor_reply: str) -> Consultation:
        consultation.doctor_reply = doctor_reply
        consultation.status = ConsultationStatus.REPLIED
        consultation.replied_at = datetime.datetime.utcnow()
        db.commit()
        db.refresh(consultation)
        return consultation
