from sqlalchemy import Column, Integer, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from database import Base


class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(Text, nullable=False)
    city = Column(Text, nullable=False)
    date = Column(Text, nullable=False)
    club = Column(Text, nullable=False)
    music_type = Column(Text, nullable=False)
    image_url = Column(Text, default="")
    cloudinary_public_id = Column(Text, default="")
    source_name = Column(Text, default="manual")
    source_url = Column(Text, default="")
    external_id = Column(Text, default="")
    is_verified = Column(Integer, default=1)
    imported_at = Column(Text, default="")
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    owner = relationship("User", back_populates="events")
    saved_by_users = relationship("UserEvent", back_populates="event")


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(Text, unique=True, nullable=False)
    email = Column(Text, unique=True, nullable=False)
    password = Column(Text, nullable=False)
    token = Column(Text, nullable=True)
    is_admin = Column(Integer, default=0)

    events = relationship("Event", back_populates="owner")
    saved_events = relationship("UserEvent", back_populates="user")


class UserEvent(Base):
    __tablename__ = "user_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)

    user = relationship("User", back_populates="saved_events")
    event = relationship("Event", back_populates="saved_by_users")

    __table_args__ = (
        UniqueConstraint("user_id", "event_id", name="unique_user_event"),
    )