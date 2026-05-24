from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import cloudinary
from dotenv import load_dotenv
from routers import auth_router, my_events_router, events_router, upload_router, admin_router
from database import Base, engine


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
app.include_router(my_events_router.router)
app.include_router(events_router.router)
app.include_router(upload_router.router)
app.include_router(admin_router.router)


# ---------- HOME ----------

@app.get("/")
def home():
    return {"message": "Techno Radar działa z PostgreSQL!"}


