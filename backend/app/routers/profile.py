import os
import uuid
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from app.database import db
from app.dependencies import get_current_user
from app.schemas.profile import ProfileUpdate

router = APIRouter(prefix="/profile", tags=["Profile"])

UPLOAD_DIR = "uploads"
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


@router.get("/")
async def get_profile(current_user: dict = Depends(get_current_user)):
    return {
        "id": str(current_user["_id"]),
        "first_name": current_user["first_name"],
        "last_name": current_user["last_name"],
        "phone_number": current_user["phone_number"],
        "is_verified": current_user["is_verified"],
        "kyc_status": current_user["kyc_status"],
        "profile_photo": current_user.get("profile_photo"),
        "role": current_user.get("role", "user"),
    }


@router.put("/")
async def update_profile(data: ProfileUpdate, current_user: dict = Depends(get_current_user)):
    users_collection = db["users"]

    update_data = {k: v for k, v in data.dict().items() if v is not None}

    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    await users_collection.update_one(
        {"_id": current_user["_id"]},
        {"$set": update_data}
    )

    return {"message": "Profile updated successfully", "updated_fields": update_data}


@router.post("/upload-photo")
async def upload_profile_photo(file: UploadFile = File(...), current_user: dict = Depends(get_current_user)):
    ext = os.path.splitext(file.filename)[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Only JPG/PNG images are allowed")

    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File too large (max 5MB)")

    filename = f"{uuid.uuid4()}{ext}"
    filepath = os.path.join(UPLOAD_DIR, "profile", filename)

    with open(filepath, "wb") as f:
        f.write(content)

    users_collection = db["users"]
    await users_collection.update_one(
        {"_id": current_user["_id"]},
        {"$set": {"profile_photo": filepath}}
    )

    return {"message": "Profile photo uploaded successfully", "path": filepath}