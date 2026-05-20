from fastapi import FastAPI, Depends, Query, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from datetime import datetime
import os
import cloudinary
import cloudinary.uploader
import requests
from dotenv import load_dotenv
from core.security import get_current_user, is_admin
from routers import auth_router
from database import Base, engine, get_db
from models import Event, UserEvent
from schemas import EventCreate


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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)


# ---------- TECHNO / TICKETMASTER CONFIG ----------

TECHNO_BANNER_URLS = [
    "https://res.cloudinary.com/dqbt0xxmd/image/upload/v1778592421/aditya-chinchure-ZhQCZjr9fHo-unsplash_unfcpl.jpg",
    "https://res.cloudinary.com/dqbt0xxmd/image/upload/v1778592421/josh-olalde-V1O0gBfbrO8-unsplash_ikjqu5.jpg",
    "https://res.cloudinary.com/dqbt0xxmd/image/upload/v1778592419/artem-bryzgalov-4EQVWx5tvp0-unsplash_k7kvnf.jpg",
    "https://res.cloudinary.com/dqbt0xxmd/image/upload/v1778592416/shawn-kAkcJwphYkY-unsplash_lwlt7i.jpg",
    "https://res.cloudinary.com/dqbt0xxmd/image/upload/v1778592415/aditya-chinchure-9tZhyQskezA-unsplash_lc9qqe.jpg",
    "https://res.cloudinary.com/dqbt0xxmd/image/upload/v1778592412/artem-bryzgalov-4EQVWx5tvp0-unsplash_1_fbkawl.jpg"
]


TECHNO_KEYWORDS = [
    "techno",
    "hard techno",
    "acid techno",
    "industrial techno",
    "minimal techno",
    "melodic techno",
    "electronic",
    "dance",
    "edm",
    "house",
    "tech house",
    "deep house",
    "trance",
    "psytrance",
    "drum and bass",
    "dnb",
    "dubstep",
    "rave"
]


TICKETMASTER_SEARCH_KEYWORDS = [
    "techno",
    "hard techno",
    "acid techno",
    "industrial techno",
    "minimal techno",
    "melodic techno",
    "electronic",
    "dance",
    "edm",
    "house",
    "tech house",
    "deep house",
    "trance",
    "psytrance",
    "drum and bass",
    "dnb",
    "dubstep",
    "rave"
]


def get_banner_url_by_index(index: int):
    if not TECHNO_BANNER_URLS:
        return ""

    return TECHNO_BANNER_URLS[index % len(TECHNO_BANNER_URLS)]


def build_ticketmaster_search_text(item: dict):
    parts = []

    name = item.get("name", "")
    if name:
        parts.append(name)

    classifications = item.get("classifications", [])

    for classification in classifications:
        segment = classification.get("segment", {}).get("name", "")
        genre = classification.get("genre", {}).get("name", "")
        sub_genre = classification.get("subGenre", {}).get("name", "")
        type_name = classification.get("type", {}).get("name", "")
        sub_type = classification.get("subType", {}).get("name", "")

        for value in [segment, genre, sub_genre, type_name, sub_type]:
            if value:
                parts.append(value)

    return " ".join(parts).lower()


def is_electronic_event(search_text: str):
    return any(keyword in search_text for keyword in TECHNO_KEYWORDS)


def detect_music_type(search_text: str):
    text = search_text.lower()

    if "acid techno" in text or "acid" in text:
        return "Acid Techno"

    if "hard techno" in text:
        return "Hard Techno"

    if "industrial techno" in text or "industrial" in text:
        return "Industrial Techno"

    if "minimal techno" in text or "minimal" in text:
        return "Minimal"

    if "tech house" in text:
        return "Tech House"

    if "deep house" in text:
        return "Deep House"

    if "house" in text:
        return "House"

    if "psytrance" in text:
        return "Psytrance"

    if "trance" in text:
        return "Trance"

    if "drum and bass" in text or "dnb" in text:
        return "Drum and Bass"

    if "dubstep" in text:
        return "Dubstep"

    if "edm" in text:
        return "EDM"

    if "rave" in text:
        return "Rave"

    if "electronic" in text or "dance" in text:
        return "Electronic"

    return "Techno"


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

    query = (
        db.query(Event)
        .filter(Event.source_name == "Ticketmaster")
        .filter(Event.is_verified == 1)
    )

    if search.strip() != "":
        search_text = f"%{search}%"

        query = query.filter(
            (Event.name.ilike(search_text)) |
            (Event.city.ilike(search_text)) |
            (Event.club.ilike(search_text)) |
            (Event.music_type.ilike(search_text))
        )

    events = (query.order_by(Event.date.asc()).limit(limit).offset(offset).all()
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
def get_public_events(year: int, db: Session = Depends(get_db)):

    year_text = f"{year}-%"

    events = (
        db.query(Event)
        .filter(Event.date.like(year_text))
        .filter(Event.is_verified == 1)
        .filter(Event.source_name == "Ticketmaster")
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
        .filter(Event.source_name == "Ticketmaster")
        .filter(Event.is_verified == 1)
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
        raise HTTPException(status_code=403, detail="Only admin can create events")

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


# ---------- MY EVENTS ----------

@app.post("/my-events/{event_id}")
def add_event_to_my_list(
    event_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    event = (
        db.query(Event)
        .filter(Event.id == event_id)
        .filter(Event.source_name == "Ticketmaster")
        .filter(Event.is_verified == 1)
        .first()
    )

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


# ---------- ADMIN IMPORT TEST EVENTS ----------

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


# ---------- ADMIN IMPORT TICKETMASTER EVENTS ----------

@app.post("/admin/import-ticketmaster-events")
def import_ticketmaster_events(
    year: int = Query(default=2026),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
            status_code=403,
            detail="Tylko admin może importować eventy"
        )

    api_key = os.getenv("TICKETMASTER_API_KEY")

    if not api_key:
        raise HTTPException(
            status_code=500,
            detail="Brak TICKETMASTER_API_KEY w .env"
        )

    url = "https://app.ticketmaster.com/discovery/v2/events.json"

    start_date_time = f"{year}-01-01T00:00:00Z"
    end_date_time = f"{year}-12-31T23:59:59Z"

    imported_count = 0
    skipped_count = 0
    banner_index = 0

    for keyword in TICKETMASTER_SEARCH_KEYWORDS:
        page = 0

        while True:
            params = {
                "apikey": api_key,
                "keyword": keyword,
                "countryCode": "PL",
                "locale": "*",
                "size": 100,
                "page": page,
                "sort": "date,asc",
                "startDateTime": start_date_time,
                "endDateTime": end_date_time
            }

            response = requests.get(url, params=params, timeout=30)

            if response.status_code != 200:
                skipped_count += 1
                break

            data = response.json()

            events_data = data.get("_embedded", {}).get("events", [])

            if not events_data:
                break

            for item in events_data:
                ticketmaster_id = item.get("id", "").strip()

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

                search_text = build_ticketmaster_search_text(item)

                if not is_electronic_event(search_text):
                    skipped_count += 1
                    continue

                name = item.get("name", "").strip()

                if not name:
                    skipped_count += 1
                    continue

                start_data = item.get("dates", {}).get("start", {})
                local_date = start_data.get("localDate", "")

                if not local_date:
                    skipped_count += 1
                    continue

                venues = item.get("_embedded", {}).get("venues", [])
                venue = venues[0] if venues else {}

                city = venue.get("city", {}).get("name", "Nieznane miasto")
                club = venue.get("name", "Nieznany obiekt")

                source_url = item.get("url", "")

                image_url = get_banner_url_by_index(banner_index)
                banner_index += 1

                music_type = detect_music_type(search_text)

                new_event = Event(
                    name=name,
                    city=city,
                    date=local_date,
                    club=club,
                    music_type=music_type,
                    image_url=image_url,
                    cloudinary_public_id="",
                    source_name="Ticketmaster",
                    source_url=source_url,
                    external_id=external_id,
                    is_verified=1,
                    imported_at=datetime.utcnow().date().isoformat(),
                    user_id=user_id
                )

                db.add(new_event)
                imported_count += 1

            db.commit()

            page_info = data.get("page", {})
            current_page = page_info.get("number", 0)
            total_pages = page_info.get("totalPages", 0)

            if current_page + 1 >= total_pages:
                break

            page += 1

    return {
        "message": "Import eventów elektronicznych z Ticketmaster zakończony",
        "year": year,
        "imported_count": imported_count,
        "skipped_count": skipped_count
    }


@app.post("/admin/update-ticketmaster-banners")
def update_ticketmaster_banners(
    year: int = Query(default=2026),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
            status_code=403,
            detail="Tylko admin może aktualizować bannery eventów"
        )

    year_text = f"{year}-%"

    events = (
        db.query(Event)
        .filter(Event.source_name == "Ticketmaster")
        .filter(Event.date.like(year_text))
        .order_by(Event.date.asc(), Event.id.asc())
        .all()
    )

    updated_count = 0

    for index, event in enumerate(events):
        event.image_url = get_banner_url_by_index(index)
        event.cloudinary_public_id = ""
        updated_count += 1

    db.commit()

    return {
        "message": "Bannery eventów Ticketmaster zostały zaktualizowane",
        "year": year,
        "updated_count": updated_count
    }


@app.get("/admin/imported-events/pending")
def get_pending_imported_events(
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
            status_code=403,
            detail="Tylko admin może widzieć eventy do zatwierdzenia"
        )

    events = (
        db.query(Event)
        .filter(Event.is_verified == 0)
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


# ---------- DELETE ----------

@app.delete("/events/{event_id}")
def delete_event(
    event_id: int,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(status_code=403, detail="Only admin can delete events")

    event = (
        db.query(Event)
        .filter(Event.id == event_id)
        .first()
    )

    if not event:
        return {"error": "Event not found"}

    if event.cloudinary_public_id:
        try:
            cloudinary.uploader.destroy(event.cloudinary_public_id)
        except Exception as error:
            raise HTTPException(
                status_code=500,
                detail=f"Nie udało się usunąć zdjęcia z Cloudinary: {str(error)}"
            )

    related_user_events = (
        db.query(UserEvent)
        .filter(UserEvent.event_id == event_id)
        .all()
    )

    for user_event in related_user_events:
        db.delete(user_event)

    db.delete(event)
    db.commit()

    return {"message": "Deleted"}


# ---------- UPDATE ----------

@app.put("/events/{event_id}")
def update_event(
    event_id: int,
    updated_event: EventCreate,
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not is_admin(user_id, db):
        raise HTTPException(
        status_code=403,
        detail="Only admin can edit events"
    )

    event = (db.query(Event).filter(Event.id == event_id).first())

    if not event:
        raise HTTPException(
            status_code=404,
            detail="Event not found"
        )


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