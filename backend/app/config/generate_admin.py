import os
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from app.config.db import SessionLocal  # Import your actual DB session maker
from app.tables.users import User, UserRole

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_initial_admin():
    db: Session = SessionLocal()
    try:
        # Check if an admin already exists to avoid duplication
        admin_exists = db.query(User).filter(User.role == UserRole.ADMIN).first()
        if admin_exists:
            print(f"⚠️ An admin account already exists: {admin_exists.email}")
            return

        print("🚀 Seeding initial admin user...")
        hashed_password = pwd_context.hash("SuperSecureAdminPassword2026!") # Choose a strong password
        
        admin_user = User(
            first_name="System",
            last_name="Administrator",
            username="admin",
            email="admin@healthmate.com",
            password=hashed_password,
            role=UserRole.ADMIN
        )
        
        db.add(admin_user)
        db.commit()
        print("✅ Super Admin created successfully!")
        print("Email: admin@healthmate.com")
        
    except Exception as e:
        db.rollback()
        print(f"❌ Failed to seed admin: {str(e)}")
    finally:
        db.close()
