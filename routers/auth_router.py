from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from database import get_db
from models import User
from schemas import UserCreate, UserLogin
from core.security import hash_password, verify_password, create_access_token


router = APIRouter()


@router.post("/register")
def register_user(
    user: UserCreate,
    db: Session = Depends(get_db)
):
    hashed_password = hash_password(user.password)

    new_user = User(
        username=user.username,
        email=user.email,
        password=hashed_password,
        is_admin=0
    )

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return {
            "message": "User registered",
            "id": new_user.id,
            "username": new_user.username,
            "email": new_user.email
        }

    except IntegrityError:
        db.rollback()
        return {"error": "User already exists"}


@router.post("/login")
def login_user(
    user: UserLogin,
    db: Session = Depends(get_db)
):
    found_user = db.query(User).filter(User.email == user.email).first()

    if found_user and verify_password(user.password, found_user.password):
        token = create_access_token({
            "user_id": found_user.id,
            "username": found_user.username,
            "email": found_user.email,
            "is_admin": found_user.is_admin
        })

        return {
            "message": "Login successful",
            "token": token,
            "id": found_user.id,
            "username": found_user.username,
            "email": found_user.email,
            "is_admin": found_user.is_admin
        }

    return {"error": "Invalid email or password"}