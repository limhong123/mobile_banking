from datetime import (
    datetime,
    timedelta,
)

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)

from app.database import db

from app.dependencies import (
    get_current_user,
)

from app.schemas.user import (
    ResendOTP,
    UserLogin,
    UserRegister,
    VerifyOTP,
)

from app.services.otp_service import (
    generate_otp,
    normalize_phone,
    send_otp_sms,
)

from app.utils.jwt_handler import (
    create_access_token,
    create_kyc_token,
    create_refresh_token,
)

from app.utils.security import (
    hash_otp,
    hash_pin,
    verify_otp_hash,
    verify_pin,
)


router = APIRouter(
    prefix="/auth",
    tags=["Auth"],
)


# =========================================================
# REGISTER
# =========================================================

@router.post("/register")
async def register(
    user: UserRegister,
):
    users = db["users"]

    phone = normalize_phone(
        user.phone_number
    )

    # -----------------------------------------------------
    # CHECK EXISTING PHONE
    # -----------------------------------------------------

    existing_user = await users.find_one(
        {
            "phone_number":
                phone,
        }
    )

    if existing_user:
        raise HTTPException(
            status_code=409,
            detail=(
                "Phone number already registered"
            ),
        )

    # -----------------------------------------------------
    # OTP
    # -----------------------------------------------------

    otp_code = generate_otp()

    now = datetime.utcnow()

    otp_expiry = (
        now
        + timedelta(
            minutes=5
        )
    )

    # -----------------------------------------------------
    # CREATE USER
    # -----------------------------------------------------

    new_user = {
        "first_name":
            user.first_name.strip(),

        "last_name":
            user.last_name.strip(),

        "phone_number":
            phone,

        "pin":
            hash_pin(
                user.pin
            ),

        "role":
            "user",

        "is_active":
            True,

        # Phone verification
        "is_verified":
            False,

        # Simple KYC flow
        "kyc_status":
            "not_submitted",

        # OTP
        "otp_hash":
            hash_otp(
                otp_code
            ),

        "otp_expiry":
            otp_expiry,

        "otp_attempts":
            0,

        "otp_resend_count":
            0,

        "otp_last_sent_at":
            now,

        # KYC data
        "kyc": {
            "nid_front_path":
                None,

            "nid_face_path":
                None,

            "selfie_path":
                None,

            "face_verified":
                False,

            "face_attempts":
                0,

            "face_match":
                None,
        },

        "created_at":
            now,

        "updated_at":
            now,
    }

    result = await users.insert_one(
        new_user
    )

    # -----------------------------------------------------
    # SEND OTP
    # -----------------------------------------------------

    otp_sent = True

    try:
        await send_otp_sms(
            phone,
            otp_code,
        )

    except Exception as error:
        otp_sent = False

        print(
            "[OTP SMS ERROR] "
            f"{error}"
        )

    return {
        "success":
            True,

        "message": (
            "Registration successful. OTP sent."
            if otp_sent
            else
            "Registration successful but OTP could not be sent."
        ),

        "user_id":
            str(
                result.inserted_id
            ),

        "otp_sent":
            otp_sent,

        "next_step": (
            "verify_otp"
            if otp_sent
            else
            "resend_otp"
        ),
    }


# =========================================================
# VERIFY OTP
# =========================================================

@router.post("/verify-otp")
async def verify_otp(
    data: VerifyOTP,
):
    users = db["users"]

    phone = normalize_phone(
        data.phone_number
    )

    user = await users.find_one(
        {
            "phone_number":
                phone,
        }
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    # -----------------------------------------------------
    # ALREADY VERIFIED
    # -----------------------------------------------------

    if user.get(
        "is_verified",
        False,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Phone number already verified"
            ),
        )

    # -----------------------------------------------------
    # ATTEMPTS
    # -----------------------------------------------------

    attempts = int(
        user.get(
            "otp_attempts",
            0,
        )
    )

    if attempts >= 5:
        raise HTTPException(
            status_code=429,
            detail=(
                "Too many invalid OTP attempts. "
                "Request a new OTP."
            ),
        )

    # -----------------------------------------------------
    # EXPIRY
    # -----------------------------------------------------

    otp_expiry = user.get(
        "otp_expiry"
    )

    if (
        not otp_expiry
        or datetime.utcnow()
        > otp_expiry
    ):
        raise HTTPException(
            status_code=400,
            detail="OTP expired",
        )

    # -----------------------------------------------------
    # VERIFY
    # -----------------------------------------------------

    stored_hash = user.get(
        "otp_hash"
    )

    if (
        not stored_hash
        or not verify_otp_hash(
            data.otp_code,
            stored_hash,
        )
    ):
        await users.update_one(
            {
                "_id":
                    user["_id"],
            },
            {
                "$inc": {
                    "otp_attempts":
                        1,
                }
            },
        )

        raise HTTPException(
            status_code=400,
            detail="Invalid OTP",
        )

    # -----------------------------------------------------
    # VERIFIED
    # -----------------------------------------------------

    now = datetime.utcnow()

    await users.update_one(
        {
            "_id":
                user["_id"],
        },
        {
            "$set": {
                "is_verified":
                    True,

                "kyc_status":
                    "not_submitted",

                "updated_at":
                    now,
            },

            "$unset": {
                "otp_hash":
                    "",

                "otp_expiry":
                    "",

                "otp_attempts":
                    "",
            },
        },
    )

    # -----------------------------------------------------
    # CREATE KYC TOKEN
    # -----------------------------------------------------

    kyc_token = create_kyc_token(
        {
            "sub":
                str(
                    user["_id"]
                ),

            "phone_number":
                phone,

            "purpose":
                "kyc",
        }
    )

    return {
        "success":
            True,

        "message":
            "Phone verified successfully",

        "kyc_token":
            kyc_token,

        "kyc_status":
            "not_submitted",

        "next_step":
            "scan_nid_front",
    }


# =========================================================
# RESEND OTP
# =========================================================

@router.post("/resend-otp")
async def resend_otp(
    data: ResendOTP,
):
    users = db["users"]

    phone = normalize_phone(
        data.phone_number
    )

    user = await users.find_one(
        {
            "phone_number":
                phone,
        }
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )

    if user.get(
        "is_verified",
        False,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Phone already verified"
            ),
        )

    now = datetime.utcnow()

    # -----------------------------------------------------
    # WAIT 60 SECONDS
    # -----------------------------------------------------

    last_sent = user.get(
        "otp_last_sent_at"
    )

    if last_sent:
        elapsed = (
            now - last_sent
        ).total_seconds()

        if elapsed < 60:
            retry_after = int(
                60 - elapsed
            )

            raise HTTPException(
                status_code=429,
                detail={
                    "message": (
                        "Please wait before requesting another OTP"
                    ),

                    "retry_after":
                        retry_after,
                },
            )

    # -----------------------------------------------------
    # LIMIT
    # -----------------------------------------------------

    resend_count = int(
        user.get(
            "otp_resend_count",
            0,
        )
    )

    if resend_count >= 5:
        raise HTTPException(
            status_code=429,
            detail=(
                "OTP resend limit reached"
            ),
        )

    # -----------------------------------------------------
    # NEW OTP
    # -----------------------------------------------------

    otp_code = generate_otp()

    expiry = (
        now
        + timedelta(
            minutes=5
        )
    )

    await users.update_one(
        {
            "_id":
                user["_id"],
        },
        {
            "$set": {
                "otp_hash":
                    hash_otp(
                        otp_code
                    ),

                "otp_expiry":
                    expiry,

                "otp_attempts":
                    0,

                "otp_last_sent_at":
                    now,
            },

            "$inc": {
                "otp_resend_count":
                    1,
            },
        },
    )

    try:
        await send_otp_sms(
            phone,
            otp_code,
        )

    except Exception as error:
        raise HTTPException(
            status_code=502,
            detail=(
                "Failed to send OTP"
            ),
        ) from error

    return {
        "success":
            True,

        "message":
            "OTP resent successfully",

        "expires_in":
            300,

        "resend_after":
            60,
    }


# =========================================================
# LOGIN
# =========================================================

@router.post("/login")
async def login(
    data: UserLogin,
):
    users = db["users"]

    phone = normalize_phone(
        data.phone_number
    )

    user = await users.find_one(
        {
            "phone_number":
                phone,
        }
    )

    # -----------------------------------------------------
    # USER / PIN
    # -----------------------------------------------------

    if not user:
        raise HTTPException(
            status_code=401,
            detail=(
                "Invalid phone number or PIN"
            ),
        )

    stored_pin = user.get(
        "pin"
    )

    if (
        not stored_pin
        or not verify_pin(
            data.pin,
            stored_pin,
        )
    ):
        raise HTTPException(
            status_code=401,
            detail=(
                "Invalid phone number or PIN"
            ),
        )

    # -----------------------------------------------------
    # ACTIVE
    # -----------------------------------------------------

    if not user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "Your account has been disabled"
            ),
        )

    role = str(
        user.get(
            "role",
            "user",
        )
    ).lower()

    # -----------------------------------------------------
    # CUSTOMER
    # -----------------------------------------------------

    if role == "user":

        # Phone OTP not verified
        if not user.get(
            "is_verified",
            False,
        ):
            raise HTTPException(
                status_code=403,
                detail={
                    "message":
                        "Phone verification required",

                    "next_step":
                        "verify_otp",
                },
            )

        kyc_status = user.get(
            "kyc_status",
            "not_submitted",
        )

        # Customer must complete:
        # NID Front + Live Face
        if kyc_status != "approved":
            raise HTTPException(
                status_code=403,
                detail={
                    "message": (
                        "Please complete identity verification"
                    ),

                    "kyc_status":
                        kyc_status,

                    "next_step":
                        "kyc",
                },
            )

    # -----------------------------------------------------
    # ADMIN / AGENT
    # -----------------------------------------------------

    elif role in [
        "admin",
        "agent",
    ]:
        kyc_status = (
            "not_required"
        )

    else:
        raise HTTPException(
            status_code=403,
            detail=(
                "Invalid account role"
            ),
        )

    # -----------------------------------------------------
    # TOKEN
    # -----------------------------------------------------

    token_data = {
        "sub":
            str(
                user["_id"]
            ),

        "phone_number":
            phone,

        "role":
            role,
    }

    access_token = (
        create_access_token(
            token_data
        )
    )

    refresh_token = (
        create_refresh_token(
            token_data
        )
    )

    return {
        "success":
            True,

        "access_token":
            access_token,

        "refresh_token":
            refresh_token,

        "token_type":
            "bearer",

        "user": {
            "id":
                str(
                    user["_id"]
                ),

            "first_name":
                user.get(
                    "first_name",
                    "",
                ),

            "last_name":
                user.get(
                    "last_name",
                    "",
                ),

            "phone_number":
                phone,

            "role":
                role,

            "is_active":
                user.get(
                    "is_active",
                    True,
                ),

            "is_verified":
                user.get(
                    "is_verified",
                    False,
                ),

            "kyc_status":
                kyc_status,
        },
    }


# =========================================================
# CURRENT USER
# =========================================================

@router.get("/me")
async def get_me(
    current_user: dict = Depends(
        get_current_user
    ),
):
    return {
        "success":
            True,

        "data": {
            "id":
                str(
                    current_user["_id"]
                ),

            "first_name":
                current_user.get(
                    "first_name",
                    "",
                ),

            "last_name":
                current_user.get(
                    "last_name",
                    "",
                ),

            "phone_number":
                current_user.get(
                    "phone_number",
                    "",
                ),

            "role":
                current_user.get(
                    "role",
                    "user",
                ),

            "is_active":
                current_user.get(
                    "is_active",
                    True,
                ),

            "is_verified":
                current_user.get(
                    "is_verified",
                    False,
                ),

            "kyc_status":
                current_user.get(
                    "kyc_status",
                    "not_submitted",
                ),

            "profile_photo":
                current_user.get(
                    "profile_photo",
                    "",
                ),

            "nid_data":
                (
                    (current_user.get("kyc") or {}).get("nid_data")
                    or current_user.get("nid_data")
                    or {}
                ),
        },
    }


# =========================================================
# RESUME KYC
# =========================================================

@router.post("/resume-kyc")
async def resume_kyc(
    data: UserLogin,
):
    users = db["users"]

    phone = normalize_phone(
        data.phone_number
    )

    user = await users.find_one(
        {
            "phone_number":
                phone,
        }
    )

    if not user:
        raise HTTPException(
            status_code=401,
            detail=(
                "Invalid phone number or PIN"
            ),
        )

    stored_pin = user.get(
        "pin"
    )

    if (
        not stored_pin
        or not verify_pin(
            data.pin,
            stored_pin,
        )
    ):
        raise HTTPException(
            status_code=401,
            detail=(
                "Invalid phone number or PIN"
            ),
        )

    # -----------------------------------------------------
    # PHONE NOT VERIFIED
    # -----------------------------------------------------

    if not user.get(
        "is_verified",
        False,
    ):
        raise HTTPException(
            status_code=403,
            detail={
                "message":
                    "Phone verification required",

                "next_step":
                    "verify_otp",
            },
        )

    # -----------------------------------------------------
    # KYC STATUS
    # -----------------------------------------------------

    kyc_status = user.get(
        "kyc_status",
        "not_submitted",
    )

    # Already completed
    if kyc_status == "approved":
        return {
            "success":
                True,

            "message":
                "KYC already approved",

            "kyc_status":
                "approved",

            "next_step":
                "login",
        }

    # -----------------------------------------------------
    # NEW KYC TOKEN
    # -----------------------------------------------------

    kyc_token = create_kyc_token(
        {
            "sub":
                str(
                    user["_id"]
                ),

            "phone_number":
                phone,

            "purpose":
                "kyc",
        }
    )

    # -----------------------------------------------------
    # SIMPLE FLOW
    # -----------------------------------------------------

    steps = {
        "not_submitted":
            "scan_nid_front",

        "nid_uploaded":
            "face_scan",

        "rejected":
            "scan_nid_front",
    }

    next_step = steps.get(
        kyc_status,
        "scan_nid_front",
    )

    return {
        "success":
            True,

        "message":
            "KYC session resumed successfully",

        "kyc_token":
            kyc_token,

        "kyc_status":
            kyc_status,

        "next_step":
            next_step,
    }