from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

events = []

class Event(BaseModel):
    nazwa: str
    miasto: str
    data: str
    klub: str
    typ_muzyki: str

@app.get("/")
def home():
    return{"message":"API działa"}

@app.get("/events")
def get_events():
    return events

@app.post("/events")
def add_event(event: Event):
    events.append(event)
    return {"message": "Dodano event"}