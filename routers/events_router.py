from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
import cloudinary.uploader
from services.date_service import get_polish_day_of_week
from database import get_db
from models import Event, UserEvent
from schemas import EventCreate
from core.security import get_current_user, is_admin


router = APIRouter()

@router.get("/events")
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

    events = (
        query.order_by(Event.date.asc())
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
            "day_of_week": get_polish_day_of_week(event.date),
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

@router.get("/public-events")
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
            "day_of_week": get_polish_day_of_week(event.date),
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

    return {
        "id": new_event.id,
        "name": new_event.name,
        "city": new_event.city,
        "date": new_event.date,
        "day_of_week": get_polish_day_of_week(event.date),
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