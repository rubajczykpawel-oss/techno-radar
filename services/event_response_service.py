from services.date_service import get_polish_day_of_week, get_polish_formatted_date
from services.city_service import get_polish_city_name

def build_event_response(event):
    return {
        "id": event.id,
        "name": event.name,
        "city": event.city,
        "city_display": get_polish_city_name(event.city),
        "date": event.date,
        "day_of_week": get_polish_day_of_week(event.date),
        "formatted_date": get_polish_formatted_date(event.date),
        "club": event.club,
        "music_type": event.music_type,
        "image_url": event.image_url,
        "cloudinary_public_id": event.cloudinary_public_id,
        "source_name": event.source_name,
        "source_url": event.source_url,
        "external_id": event.external_id,
        "is_verified": event.is_verified,
        "imported_at": event.imported_at
    }