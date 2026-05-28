from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
import cloudinary.uploader
from services.date_service import get_polish_day_of_week
from services.city_service import get_polish_city_name
from database import get_db
from models import Event, UserEvent
from schemas import EventCreate
from core.security import get_current_user, is_admin
from services.event_response_service import build_event_response
from datetime import date

router = APIRouter()

@router.get("/event-filter-options")
def get_event_filter_options(
    db: Session = Depends(get_db)
):
    today_text = date.today().isoformat()

    rows = (
        db.query(Event.city, Event.music_type)
        .filter(Event.source_name == "Ticketmaster")
        .filter(Event.is_verified == 1)
        .filter(Event.date >= today_text)
        .all()
    )

    city_values = set()
    music_type_values = set()

    for city, music_type in rows:
        if city and city.strip() != "":
            city_values.add(city.strip())

        if music_type and music_type.strip() != "":
            music_type_values.add(music_type.strip())

    cities = []

    for city in city_values:
        cities.append({
            "value": city,
            "label": get_polish_city_name(city)
        })

    music_types = []

    for music_type in music_type_values:
        if music_type == "Electronic":
            label = "Muzyka elektroniczna"
        else:
            label = music_type

        music_types.append({
            "value": music_type,
            "label": label
        })

    cities.sort(key=lambda item: item["label"])
    music_types.sort(key=lambda item: item["label"])

    return {
        "cities": cities,
        "music_types": music_types
    }

@router.get("/events")
def get_events(
    user_id: int = Depends(get_current_user),
    search: str = Query(default=""),
    city: str = Query(default=""),
    music_type: str = Query(default=""),
    page: int = Query(default=1),
    limit: int = Query(default=5),
    db: Session = Depends(get_db),
    year: int = Query(default=0),
    month: int = Query(default=0)
):
    if page < 1:
        page = 1

    if limit < 1:
        limit = 5
    
    if month < 0 or month > 12:
        raise HTTPException(status_code=400, detail="Month must be between 1 and 12")

    offset = (page - 1) * limit
    today_text = date.today().isoformat()

    query = (
        db.query(Event)
        .filter(Event.source_name == "Ticketmaster")
        .filter(Event.is_verified == 1)
        .filter(Event.date >= today_text)
    )

    if search.strip() != "":
        search_text = f"%{search}%"

        query = query.filter(
            (Event.name.ilike(search_text)) |
            (Event.city.ilike(search_text)) |
            (Event.club.ilike(search_text)) |
            (Event.music_type.ilike(search_text))
        )
    if city.strip() != "":
        city_text = f"%{city}%"

        query = query.filter(Event.city.ilike(city_text))

    if music_type.strip() != "":
        music_type_text = f"%{music_type}%"

        query = query.filter(Event.music_type.ilike(music_type_text))

    if year > 0 and month > 0:
        month_text = f"{year}-{month:02d}-%"
        query = query.filter(Event.date.like(month_text))
    elif year > 0:
        year_text = f"{year}-%"
        query = query.filter(Event.date.like(year_text))

    events = (
        query.order_by(Event.date.asc())
        .limit(limit)
        .offset(offset)
        .all()
    )

    result = []

    for event in events:
        result.append(build_event_response(event))

    return result

@router.get("/public-events")
def get_public_events(
    year: int,
    month: int = Query(default=0), 
    db: Session = Depends(get_db)
):
    if month < 0 or month > 12:
        raise HTTPException(
            status_code=400, 
            detail="Month must be between 1 and 12"
        )

    today_text = date.today().isoformat()

    if month > 0:
        date_text = f"{year}-{month:02d}-%"
    else:
        date_text = f"{year}-%"

    events = (
        db.query(Event)
        .filter(Event.date.like(date_text))
        .filter(Event.date >= today_text)
        .filter(Event.is_verified == 1)
        .filter(Event.source_name == "Ticketmaster")
        .order_by(Event.date.asc())
        .all()
    )

    result = []

    for event in events:
        result.append(build_event_response(event))

    return result

@router.post("/events")
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

    return build_event_response(new_event)

@router.delete("/events/{event_id}")
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

@router.put("/events/{event_id}")
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