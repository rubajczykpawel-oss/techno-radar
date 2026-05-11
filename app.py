from fastapi import FastAPI, Depends, Query, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from jose import jwt, JWTError
from datetime import datetime, timedelta
from passlib.context import CryptContext
import os
import cloudinary
import cloudinary.uploader
import requests
from dotenv import load_dotenv 
from database import Base, engine, get_db
from models import Event, User, UserEvent
from schemas import EventCreate, UserCreate, UserLogin

load_dotenv()

cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

app = FastAPI()

# Tworzymy tabele w bazie danych na podstawie models.py
Base.metadata.create_all(bind=engine)



# ---------- CORS ----------
# UWAGA:
# allow_origins=["*"] jest wygodne do nauki i lokalnego testowania.
# Przed produkcją najlepiej zmienić "*" na konkretne adresy frontendu.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- AUTH CONFIG ----------

SECRET_KEY = os.getenv("SECRET_KEY")

if not SECRET_KEY:
    raise ValueError("Brak SECRET_KEY w pliku.env")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

bearer_scheme = HTTPBearer(auto_error=False)


# ---------- AUTH FUNCTIONS ----------

def create_access_token(data: dict):
    to_encode = data.copy()

    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({
        "exp": expire
    })

    encoded_jwt = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return encoded_jwt


def hash_password(password: str):
    return pwd_context.hash(password)


def verify_password(plain_password, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
):
    if not credentials:
        raise HTTPException(status_code=401, detail="Brak tokena")
    
    token = credentials.credentials

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("user_id")

        if not user_id:
            raise HTTPException(status_code=401, detail="Token niepoprawny lub wygasł")
        
        return user_id
    
    except JWTError:
        raise HTTPException(status_code=401, detail="Token niepoprawny lub wygasł")
    

def is_admin(user_id: int, db: Session):
    user = db.query(User).filter(User.id == user_id).first()

    if user and user.is_admin == 1:
        return True

    return False


# ---------- HOME ----------

@app.get("/")
def home():
    return {"message": "Techno Radar działa z PostgreSQL!"}


# ---------- GET EVENTS ----------

@app.get("/events")
def get_events(
    user_id: int = Depends(get_current_user),
    search: str = Query(default=""),
    page: int = Query(default=1),
    limit: int = Query(default=5),
    db: Session = Depends(get_db)
):
    if page < 1:
        page = 1

    if limit < 1:
        limit = 5

    offset = (page - 1) * limit

    query = db.query(Event).filter(Event.user_id == user_id)

    if search.strip() != "":
        search_text = f"%{search}%"

        query = query.filter(
            (Event.name.ilike(search_text)) |
            (Event.city.ilike(search_text)) |
            (Event.club.ilike(search_text)) |
            (Event.music_type.ilike(search_text))
        )

    events = (
        query
        .order_by(Event.date.asc())
        .limit(limit)
        .offset(offset)
        .all()
    )

    result = []

    for event in events:
        result.append({
            "id": event.id,
            "name": event.name,
            "city": event.city,
            "date": event.date,
            "club": event.club,
            "music_type": event.music_type,
            "image_url": event.image_url,
            "cloudinary_public_id": event.cloudinary_public_id,
            "source_name": event.source_name,
            "source_url": event.source_url,
            "external_id": event.external_id,
            "is_verified": event.is_verified,
            "imported_at": event.imported_at    
        })

    return result


@app.get("/public-events")
def get_public_events(
    year: int,
    db: Session = Depends(get_db)
):
    year_text = f"{year}-%"

    events = (
        db.query(Event)
        .filter(Event.date.like(year_text))
        .filter(Event.is_verified == 1)
        .order_by(Event.date.asc())
        .all()
    )

    result = []

    for event in events:
        result.append({
            "id": event.id,
            "name": event.name,
            "city": event.city,
            "date": event.date,
            "club": event.club,
            "music_type": event.music_type,
            "image_url": event.image_url,
            "cloudinary_public_id": event.cloudinary_public_id,
            "source_name": event.source_name,
            "source_url": event.source_url,
            "external_id": event.external_id,
            "is_verified": event.is_verified,
            "imported_at": event.imported_at
        })

    return result


@app.get("/my-events")
def get_my_events(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    saved_events = (
        db.query(Event)
        .join(UserEvent, Event.id == UserEvent.event_id)
        .filter(UserEvent.user_id == user_id)
        .order_by(Event.date.asc())
        .all()
    )

    result = []

    for event in saved_events:
        result.append({
            "id": event.id,
            "name": event.name,
            "city": event.city,
            "date": event.date,
            "club": event.club,
            "music_type": event.music_type,
            "image_url": event.image_url,
            "cloudinary_public_id": event.cloudinary_public_id,
            "source_name": event.source_name,
            "source_url": event.source_url,
            "external_id": event.external_id,
            "is_verified": event.is_verified,
            "imported_at": event.imported_at
        })

    return result


# ---------- UPLOAD IMAGE ----------

@app.post("/upload-image")
def upload_image(file: UploadFile = File(...)):
    filename = file.filename.lower()

    allowed_extensions = [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]

    if not any(filename.endswith(extension) for extension in allowed_extensions):
        raise HTTPException(
            status_code=400,
            detail="Dozwolone są tylko pliki JPG, JPEG, PNG i WEBP"
        )

    contents = file.file.read()

    max_size = 10 * 1024 * 1024

    if len(contents) > max_size:
        raise HTTPException(
            status_code=400,
            detail="Maksymalny rozmiar zdjęcia to 10MB"
        )

    try:
        upload_result = cloudinary.uploader.upload(
            contents,
            folder="techno_radar/events"
        )

        image_url = upload_result.get("secure_url")
        public_id = upload_result.get("public_id")

        if not image_url:
            raise HTTPException(
                status_code=500,
                detail="Cloudinary nie zwróciło linku do zdjęcia"
            )
        if not public_id:
            raise HTTPException(
                status_code=500,
                detail="Cloudinary nie zwróciło public_id zdjęcia"
            )

        return {
            "image_url": image_url,
            "public_id": public_id
        }

    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Błąd uploadu do Cloudinary: {str(error)}"
        )


# ---------- CREATE ----------

@app.post("/events")
def create_event(
    event: EventCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        return {"error": "Only admin can create events"}

    new_event = Event(
    name=event.name,
    city=event.city,
    date=event.date,
    club=event.club,
    music_type=event.music_type,
    image_url=event.image_url,
    cloudinary_public_id=event.cloudinary_public_id,
    source_name=event.source_name,
    source_url=event.source_url,
    external_id=event.external_id,
    is_verified=event.is_verified,
    imported_at=event.imported_at,
    user_id=user_id
)

    db.add(new_event)
    db.commit()
    db.refresh(new_event)

    return {
    "id": new_event.id,
    "name": new_event.name,
    "city": new_event.city,
    "date": new_event.date,
    "club": new_event.club,
    "music_type": new_event.music_type,
    "image_url": new_event.image_url,
    "cloudinary_public_id": new_event.cloudinary_public_id,
    "source_name": new_event.source_name,
    "source_url": new_event.source_url,
    "external_id": new_event.external_id,
    "is_verified": new_event.is_verified,
    "imported_at": new_event.imported_at
}
    


@app.post("/register")
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


@app.post("/login")
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


@app.post("/my-events/{event_id}")
def add_event_to_my_list(
    event_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    event = db.query(Event).filter(Event.id == event_id).first()

    if not event:
        return {"error": "Event not found"}

    new_user_event = UserEvent(
        user_id=user_id,
        event_id=event_id
    )

    try:
        db.add(new_user_event)
        db.commit()

        return {"message": "Event added to your list"}

    except IntegrityError:
        db.rollback()
        return {"error": "Event already added"}
    
@app.post("/admin/import-test-events")
def import_test_events(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
            status_code=403,
            detail="Tylko admin może importować eventy"
        )

    test_events = [
        {
            "name": "Imported Techno Night Warsaw",
            "city": "Warszawa",
            "date": "2026-11-01",
            "club": "Test Club Warsaw",
            "music_type": "Techno",
            "image_url": "",
            "cloudinary_public_id": "",
            "source_name": "test_import",
            "source_url": "https://example.com/events/imported-techno-night-warsaw",
            "external_id": "test_import_001",
            "is_verified": 0,
            "imported_at": "2026-05-10"
        },
        {
            "name": "Imported Hard Techno Krakow",
            "city": "Kraków",
            "date": "2026-11-15",
            "club": "Test Club Krakow",
            "music_type": "Hard Techno",
            "image_url": "",
            "cloudinary_public_id": "",
            "source_name": "test_import",
            "source_url": "https://example.com/events/imported-hard-techno-krakow",
            "external_id": "test_import_002",
            "is_verified": 0,
            "imported_at": "2026-05-10"
        },
        {
            "name": "Imported Acid Techno Gdansk",
            "city": "Gdańsk",
            "date": "2026-12-01",
            "club": "Test Club Gdansk",
            "music_type": "Acid Techno",
            "image_url": "",
            "cloudinary_public_id": "",
            "source_name": "test_import",
            "source_url": "https://example.com/events/imported-acid-techno-gdansk",
            "external_id": "test_import_003",
            "is_verified": 0,
            "imported_at": "2026-05-10"
        }
    ]

    imported_count = 0
    skipped_count = 0

    for item in test_events:
        existing_event = (
            db.query(Event)
            .filter(Event.external_id == item["external_id"])
            .first()
        )

        if existing_event:
            skipped_count += 1
            continue

        new_event = Event(
            name=item["name"],
            city=item["city"],
            date=item["date"],
            club=item["club"],
            music_type=item["music_type"],
            image_url=item["image_url"],
            cloudinary_public_id=item["cloudinary_public_id"],
            source_name=item["source_name"],
            source_url=item["source_url"],
            external_id=item["external_id"],
            is_verified=item["is_verified"],
            imported_at=item["imported_at"],
            user_id=user_id
        )

        db.add(new_event)
        imported_count += 1

    db.commit()

    return {
        "message": "Import testowych eventów zakończony",
        "imported_count": imported_count,
        "skipped_count": skipped_count
    }

@app.post("/admin/import-ticketmaster-events")
def import_ticketmaster_events(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
            status_code=403,
            detail="Tylko admin może importować eventy"
        )

    ticketmaster_api_key = os.getenv("TICKETMASTER_API_KEY")

    if not ticketmaster_api_key:
        raise HTTPException(
            status_code=500,
            detail="Brak TICKETMASTER_API_KEY w zmiennych środowiskowych"
        )

    url = "https://app.ticketmaster.com/discovery/v2/events.json"

    params = {
        "apikey": ticketmaster_api_key,
        "keyword": "techno",
        "countryCode": "PL",
        "size": 20,
        "sort": "date,asc"
    }

    response = requests.get(url, params=params, timeout=15)

    if response.status_code != 200:
        raise HTTPException(
            status_code=500,
            detail=f"Błąd Ticketmaster API: {response.status_code} {response.text}"
        )

    data = response.json()

    embedded = data.get("_embedded", {})
    ticketmaster_events = embedded.get("events", [])

    imported_count = 0
    skipped_count = 0

    for item in ticketmaster_events:
        ticketmaster_id = item.get("id", "")

        if not ticketmaster_id:
            skipped_count += 1
            continue

        external_id = f"ticketmaster_{ticketmaster_id}"

        existing_event = (
            db.query(Event)
            .filter(Event.external_id == external_id)
            .first()
        )

        if existing_event:
            skipped_count += 1
            continue

        name = item.get("name", "Ticketmaster event")

        dates = item.get("dates", {})
        start = dates.get("start", {})
        local_date = start.get("localDate", "")

        event_url = item.get("url", "")

        images = item.get("images", [])
        image_url = ""

        if images:
            image_url = images[0].get("url", "")

        city = ""
        club = ""

        item_embedded = item.get("_embedded", {})
        venues = item_embedded.get("venues", [])

        if venues:
            first_venue = venues[0]
            club = first_venue.get("name", "")

            city_data = first_venue.get("city", {})
            city = city_data.get("name", "")

        new_event = Event(
            name=name,
            city=city,
            date=local_date,
            club=club,
            music_type="Techno",
            image_url=image_url,
            cloudinary_public_id="",
            source_name="Ticketmaster",
            source_url=event_url,
            external_id=external_id,
            is_verified=0,
            imported_at=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            user_id=user_id
        )

        db.add(new_event)
        imported_count += 1

    db.commit()

    return {
        "message": "Import Ticketmaster zakończony",
        "imported_count": imported_count,
        "skipped_count": skipped_count,
        "ticketmaster_results": len(ticketmaster_events)
    }



# ---------- DELETE ----------

@app.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        return {"error": "Only admin can delete events"}

    event = (
        db.query(Event)
        .filter(Event.id == event_id, Event.user_id == user_id)
        .first()
    )

    if not event:
        return {"error": "Event not found or access denied"}

    if event.cloudinary_public_id:
        try:
            cloudinary.uploader.destroy(event.cloudinary_public_id)
        except Exception as error:
            raise HTTPException(
                status_code=500,
                detail=f"Nie udało się usunąć zdjęcia z Cloudinary: {str(error)}"
            )

    db.delete(event)
    db.commit()

    return {"message": "Deleted"}


@app.delete("/my-events/{event_id}")
def remove_event_from_my_list(
    event_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user_event = (
        db.query(UserEvent)
        .filter(UserEvent.user_id == user_id, UserEvent.event_id == event_id)
        .first()
    )

    if not user_event:
        return {"error": "Event not found on your list"}

    db.delete(user_event)
    db.commit()

    return {"message": "Event removed from your list"}


# ---------- UPDATE ----------

@app.put("/events/{event_id}")
def update_event(
    event_id: int,
    updated_event: EventCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        return {"error": "Only admin can edit events"}

    event = (
        db.query(Event)
        .filter(Event.id == event_id, Event.user_id == user_id)
        .first()
    )

    if not event:
        return {"error": "Event not found or access denied"}

    old_image_url = event.image_url or ""

    if old_image_url and old_image_url != updated_event.image_url:
        old_filename = old_image_url.split("/")[-1]
        old_file_path = f"uploads/{old_filename}"

        if os.path.exists(old_file_path):
            os.remove(old_file_path)

    event.name = updated_event.name
    event.city = updated_event.city
    event.date = updated_event.date
    event.club = updated_event.club
    event.music_type = updated_event.music_type
    event.image_url = updated_event.image_url
    event.cloudinary_public_id = updated_event.cloudinary_public_id
    event.source_name = updated_event.source_name
    event.source_url = updated_event.source_url
    event.external_id = updated_event.external_id
    event.is_verified = updated_event.is_verified
    event.imported_at = updated_event.imported_at
    db.commit()
    db.refresh(event)

    return {"message": "Updated"}

@app.put("/admin/events/{event_id}/verify")
def verify_imported_event(
    event_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
            status_code=403,
            detail="Tylko admin może zatwierdzać eventy"
        )

    event = db.query(Event).filter(Event.id == event_id).first()

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Event nie istnieje"
        )

    event.is_verified = 1

    db.commit()
    db.refresh(event)

    return {
        "message": "Event został zatwierdzony",
        "id": event.id,
        "name": event.name,
        "is_verified": event.is_verified,
        "source_name": event.source_name,
        "source_url": event.source_url,
        "external_id": event.external_id
    }