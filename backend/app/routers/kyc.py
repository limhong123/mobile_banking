from pathlib import Path
import uuid

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
)

from app.database import db

from app.dependencies import (
    get_current_kyc_user,
)

from app.services.face_service import (
    extract_face_from_nid,
    verify_face_match,
)

from app.services.nid_ocr_service import (
    extract_nid_data,
)


router = APIRouter(
    prefix="/kyc",
    tags=["KYC"],
)


# =========================================================
# CONFIG
# =========================================================

UPLOAD_DIR = Path(
    "uploads/kyc"
)

UPLOAD_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# =========================================================
# SAVE IMAGE
# =========================================================

async def save_image(
    file: UploadFile,
    prefix: str,
) -> str:
    filename = (
        file.filename or ""
    )

    extension = (
        Path(filename)
        .suffix
        .lower()
    )

    allowed_extensions = {
        ".jpg",
        ".jpeg",
        ".png",
    }

    allowed_content_types = {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "application/octet-stream",
    }

    print(
        "========== KYC IMAGE =========="
    )

    print(
        f"filename={filename}"
    )

    print(
        f"extension={extension}"
    )

    print(
        f"content_type={file.content_type}"
    )

    print(
        "==============================="
    )

    # -----------------------------------------------------
    # EXTENSION
    # -----------------------------------------------------

    if (
        extension
        and extension
        not in allowed_extensions
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Only JPEG and PNG images are allowed"
            ),
        )

    # -----------------------------------------------------
    # CONTENT TYPE
    # -----------------------------------------------------

    if (
        file.content_type
        and file.content_type
        not in allowed_content_types
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid image content type: "
                f"{file.content_type}"
            ),
        )

    # -----------------------------------------------------
    # READ
    # -----------------------------------------------------

    content = await file.read()

    if not content:
        raise HTTPException(
            status_code=400,
            detail=(
                "Image file is empty"
            ),
        )

    max_size = (
        5
        * 1024
        * 1024
    )

    if len(content) > max_size:
        raise HTTPException(
            status_code=413,
            detail=(
                "Image must be less than 5 MB"
            ),
        )

    # -----------------------------------------------------
    # FALLBACK EXTENSION
    # -----------------------------------------------------

    if not extension:
        if (
            file.content_type
            == "image/png"
        ):
            extension = ".png"
        else:
            extension = ".jpg"

    # -----------------------------------------------------
    # SAVE
    # -----------------------------------------------------

    safe_filename = (
        f"{prefix}_"
        f"{uuid.uuid4()}"
        f"{extension}"
    )

    path = (
        UPLOAD_DIR
        / safe_filename
    )

    path.write_bytes(
        content
    )

    return str(
        path
    )


# =========================================================
# NID FRONT
# =========================================================

@router.post("/nid/front")
async def upload_nid_front(
    file: UploadFile = File(...),

    current_user: dict = Depends(
        get_current_kyc_user
    ),
):
    users = db["users"]

    # -----------------------------------------------------
    # SAVE FRONT NID
    # -----------------------------------------------------

    path = await save_image(
        file,
        "nid_front",
    )

    # -----------------------------------------------------
    # RESET OLD KYC
    # -----------------------------------------------------

    await users.update_one(
        {
            "_id":
                current_user["_id"],
        },
        {
            "$set": {
                "kyc.nid_front_path":
                    path,

                "kyc_status":
                    "not_submitted",
            },

            "$unset": {
                "kyc.nid_face_path":
                    "",

                "kyc.selfie_path":
                    "",

                "kyc.face_verified":
                    "",

                "kyc.face_match":
                    "",

                "kyc.last_face_match":
                    "",

                "kyc.manual_review_required":
                    "",
            },
        },
    )

    # -----------------------------------------------------
    # OPTIONAL OCR
    #
    # OCR failure DOES NOT block KYC anymore.
    # We only need NID front + face.
    # -----------------------------------------------------

    ocr_data = {}

    try:
        ocr_data = (
            extract_nid_data(
                path
            )
            or {}
        )

        print(
            "========== OCR RESULT =========="
        )

        print(
            ocr_data
        )

        print(
            "================================"
        )

    except Exception as error:
        print(
            "[OCR WARNING] "
            f"{error}"
        )

    # -----------------------------------------------------
    # SAVE OCR IF AVAILABLE
    # -----------------------------------------------------

    nid_data = {
        "nid_number": ocr_data.get("nid_number", ""),
        "first_name": ocr_data.get("first_name", ""),
        "last_name": ocr_data.get("last_name", ""),
        "full_name": ocr_data.get("full_name", ""),
        "date_of_birth": ocr_data.get("date_of_birth", ""),
        "expiry_date": ocr_data.get("expiry_date", ""),
        "gender": ocr_data.get("gender", ""),
        "address": ocr_data.get("address", ""),
        "source": ocr_data.get("source", "ocr"),
    }

    set_fields = {
        "kyc.nid_data": nid_data,
        "nid_data": nid_data,
        "kyc.ocr_completed": bool(ocr_data.get("ocr_completed", False)),
        "kyc.ocr_raw_text": ocr_data.get("raw_text", ""),
        "kyc.mrz_lines": ocr_data.get("mrz_lines", []),
    }

    if not current_user.get("first_name") and nid_data.get("first_name"):
        set_fields["first_name"] = nid_data["first_name"]
    if not current_user.get("last_name") and nid_data.get("last_name"):
        set_fields["last_name"] = nid_data["last_name"]

    await users.update_one(
        {
            "_id": current_user["_id"],
        },
        {
            "$set": set_fields,
        },
    )

    # -----------------------------------------------------
    # EXTRACT FACE FROM NID
    #
    # THIS IS REQUIRED
    # -----------------------------------------------------

    try:
        nid_face_path = (
            extract_face_from_nid(
                path
            )
        )

    except ValueError as error:
        raise HTTPException(
            status_code=400,
            detail={
                "message": (
                    "Could not detect a clear face "
                    "on the NID. Please take the "
                    "NID photo again."
                ),

                "error":
                    str(
                        error
                    ),

                "next_step":
                    "scan_nid_front",
            },
        ) from error

    except RuntimeError as error:
        print(
            "[NID FACE ERROR] "
            f"{error}"
        )

        raise HTTPException(
            status_code=500,
            detail={
                "message": (
                    "Failed to prepare NID face"
                ),

                "next_step":
                    "scan_nid_front",
            },
        ) from error

    # -----------------------------------------------------
    # NID READY
    # -----------------------------------------------------

    await users.update_one(
        {
            "_id":
                current_user["_id"],
        },
        {
            "$set": {
                "kyc.nid_face_path":
                    nid_face_path,

                "kyc.face_verified":
                    False,

                "kyc.face_attempts":
                    0,

                "kyc_status":
                    "nid_uploaded",
            },
        },
    )

    return {
        "success":
            True,

        "message":
            "NID uploaded successfully",

        "kyc_status":
            "nid_uploaded",

        "nid_face_ready":
            True,

        "ocr_completed":
            bool(
                ocr_data.get(
                    "ocr_completed",
                    False,
                )
            ),

        "nid_data":
            nid_data,

        "next_step":
            "face_scan",
    }


# =========================================================
# LIVE FACE / FACE MATCH
# =========================================================

@router.post("/face")
async def verify_face(
    selfie: UploadFile = File(...),

    current_user: dict = Depends(
        get_current_kyc_user
    ),
):
    users = db["users"]

    # -----------------------------------------------------
    # GET FRESH USER
    # -----------------------------------------------------

    fresh_user = await users.find_one(
        {
            "_id":
                current_user["_id"],
        }
    )

    if not fresh_user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    # -----------------------------------------------------
    # CHECK NID
    # -----------------------------------------------------

    if fresh_user.get(
        "kyc_status"
    ) != "nid_uploaded":
        raise HTTPException(
            status_code=400,
            detail={
                "message": (
                    "Please upload NID first"
                ),

                "next_step":
                    "scan_nid_front",
            },
        )

    kyc = (
        fresh_user.get(
            "kyc",
            {},
        )
        or {}
    )

    nid_face_path = (
        kyc.get(
            "nid_face_path"
        )
    )

    if not nid_face_path:
        raise HTTPException(
            status_code=400,
            detail={
                "message": (
                    "NID face is not available. "
                    "Please capture NID again."
                ),

                "next_step":
                    "scan_nid_front",
            },
        )

    nid_face_file = Path(
        nid_face_path
    )

    if not nid_face_file.exists():
        raise HTTPException(
            status_code=400,
            detail={
                "message": (
                    "NID face file does not exist. "
                    "Please capture NID again."
                ),

                "next_step":
                    "scan_nid_front",
            },
        )

    # -----------------------------------------------------
    # ATTEMPTS
    # -----------------------------------------------------

    face_attempts = int(
        kyc.get(
            "face_attempts",
            0,
        )
    )

    if face_attempts >= 5:
        raise HTTPException(
            status_code=429,
            detail={
                "message": (
                    "Too many face verification attempts"
                ),

                "next_step":
                    "scan_nid_front",
            },
        )

    # -----------------------------------------------------
    # SAVE LIVE SELFIE
    # -----------------------------------------------------

    selfie_path = await save_image(
        selfie,
        "selfie",
    )

    print(
        "========== FACE MATCH =========="
    )

    print(
        f"NID FACE: {nid_face_path}"
    )

    print(
        f"LIVE FACE: {selfie_path}"
    )

    # -----------------------------------------------------
    # VERIFY
    # -----------------------------------------------------

    try:
        result = verify_face_match(
            nid_face_path,
            selfie_path,
        )

    except ValueError as error:

        await users.update_one(
            {
                "_id":
                    fresh_user["_id"],
            },
            {
                "$inc": {
                    "kyc.face_attempts":
                        1,
                },

                "$set": {
                    "kyc.selfie_path":
                        selfie_path,
                },
            },
        )

        raise HTTPException(
            status_code=400,
            detail={
                "message": (
                    "Could not detect a clear live face. "
                    "Please try again."
                ),

                "next_step":
                    "retry_face",
            },
        ) from error

    except RuntimeError as error:
        print(
            "[FACE MATCH ERROR] "
            f"{error}"
        )

        raise HTTPException(
            status_code=500,
            detail={
                "message": (
                    "Face verification failed"
                ),

                "next_step":
                    "retry_face",
            },
        ) from error

    # -----------------------------------------------------
    # LOG
    # -----------------------------------------------------

    print(
        "========== FACE RESULT =========="
    )

    print(
        f"VERIFIED: "
        f"{result.get('verified')}"
    )

    print(
        f"MATCH SCORE: "
        f"{result.get('match_score')}"
    )

    print(
        f"DISTANCE: "
        f"{result.get('distance')}"
    )

    print(
        f"THRESHOLD: "
        f"{result.get('threshold')}"
    )

    print(
        "================================="
    )

    verified = bool(
        result.get(
            "verified",
            False,
        )
    )

    # =====================================================
    # SUCCESS = AUTO APPROVE
    # =====================================================

    if verified:

        await users.update_one(
            {
                "_id":
                    fresh_user["_id"],
            },
            {
                "$set": {
                    "kyc.selfie_path":
                        selfie_path,

                    "kyc.face_verified":
                        True,

                    "kyc.face_match":
                        result,

                    "kyc.face_attempts":
                        0,

                    "kyc_status":
                        "approved",

                    "updated_at":
                        __import__(
                            "datetime"
                        )
                        .datetime
                        .utcnow(),
                },
            },
        )

        nid_data = kyc.get("nid_data") or fresh_user.get("nid_data") or {}

        return {
            "success":
                True,

            "message":
                "Identity verification successful",

            "face_verified":
                True,

            "face_match":
                result,

            "kyc_status":
                "approved",

            "nid_data":
                nid_data,

            "next_step":
                "result",
        }

    # =====================================================
    # FAILED
    # =====================================================

    await users.update_one(
        {
            "_id":
                fresh_user["_id"],
        },
        {
            "$set": {
                "kyc.selfie_path":
                    selfie_path,

                "kyc.face_verified":
                    False,

                "kyc.face_match":
                    result,

                "kyc.last_face_match":
                    result,

                "kyc_status":
                    "rejected",
            },

            "$inc": {
                "kyc.face_attempts":
                    1,
            },
        },
    )

    return {
        "success":
            False,

        "message": (
            "Face does not match the NID"
        ),

        "face_verified":
            False,

        "face_match":
            result,

        "kyc_status":
            "rejected",

        "next_step":
            "result",
    }


# =========================================================
# KYC STATUS
# =========================================================

@router.get("/status")
async def get_kyc_status(
    current_user: dict = Depends(
        get_current_kyc_user
    ),
):
    users = db["users"]

    fresh_user = await users.find_one(
        {
            "_id":
                current_user["_id"],
        }
    )

    if not fresh_user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    status_value = fresh_user.get(
        "kyc_status",
        "not_submitted",
    )

    steps = {
        "not_submitted":
            "scan_nid_front",

        "nid_uploaded":
            "face_scan",

        "approved":
            "login",

        "rejected":
            "scan_nid_front",
    }

    next_step = steps.get(
        status_value,
        "scan_nid_front",
    )

    return {
        "success":
            True,

        "kyc_status":
            status_value,

        "next_step":
            next_step,
    }


# =========================================================
# GET IDENTITY INFORMATION
# =========================================================

@router.get("/identity")
async def get_identity_information(
    current_user: dict = Depends(
        get_current_kyc_user
    ),
):
    users = db["users"]
    fresh_user = await users.find_one({"_id": current_user["_id"]})
    if not fresh_user:
        raise HTTPException(status_code=404, detail="User not found")

    kyc = fresh_user.get("kyc") or {}
    nid_data = kyc.get("nid_data") or fresh_user.get("nid_data") or {}

    first_name = nid_data.get("first_name") or fresh_user.get("first_name", "")
    last_name = nid_data.get("last_name") or fresh_user.get("last_name", "")
    full_name = nid_data.get("full_name") or f"{last_name} {first_name}".strip()

    nid_front = kyc.get("nid_front_path") or fresh_user.get("nid_image")

    return {
        "success": True,
        "kyc_status": fresh_user.get("kyc_status", "not_submitted"),
        "is_verified": bool(fresh_user.get("is_verified", False)),
        "face_verified": bool(kyc.get("face_verified", False)),
        "nid_number": nid_data.get("nid_number", ""),
        "first_name": first_name,
        "last_name": last_name,
        "full_name": full_name,
        "date_of_birth": nid_data.get("date_of_birth", ""),
        "expiry_date": nid_data.get("expiry_date", ""),
        "gender": nid_data.get("gender", ""),
        "address": nid_data.get("address", ""),
        "nid_front_url": nid_front,
        "source": nid_data.get("source", "ocr"),
    }