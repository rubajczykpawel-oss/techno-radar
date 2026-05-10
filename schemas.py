from pydantic import BaseModel, field_validator


class EventCreate(BaseModel):
    name: str
    city: str
    date: str
    club: str
    music_type: str
    image_url: str = ""
    cloudinary_public_id: str = ""
    source_name: str = "manual"
    source_url: str = ""
    external_id: str = ""
    is_verified: int = 1
    imported_at: str = ""

    @field_validator("name", "city", "date", "club", "music_type")
    @classmethod
    def not_empty(cls, value):
        if value.strip() == "":
            raise ValueError("Pole nie może być puste")
        return value


class EventResponse(BaseModel):
    id: int
    name: str
    city: str
    date: str
    club: str
    music_type: str
    image_url: str = ""
    cloudinary_public_id: str = ""
    source_name: str = "manual"
    source_url: str = ""
    external_id: str = ""
    is_verified: int = 1
    imported_at: str = ""

    class Config:
        from_attributes = True


class UserCreate(BaseModel):
    username: str
    email: str
    password: str


class UserLogin(BaseModel):
    email: str
    password: str