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