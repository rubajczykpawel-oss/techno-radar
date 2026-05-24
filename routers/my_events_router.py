from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from services.date_service import get_polish_day_of_week
from database import get_db
from models import Event, UserEvent
from core.security import get_current_user
from services.event_response_service import build_event_response


router = APIRouter()


@router.get("/my-events")
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
        result.append(build_event_response(event))

    return result


@router.post("/my-events/{event_id}")
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


@router.delete("/my-events/{event_id}")
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