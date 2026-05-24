from fastapi import APIRouter, HTTPException, UploadFile, File
import cloudinary.uploader


router = APIRouter()


@router.post("/upload-image")
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