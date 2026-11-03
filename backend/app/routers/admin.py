from datetime import (
    datetime,
    timezone,
)
from decimal import Decimal
from pathlib import Path
from uuid import uuid4
from bson import ObjectId
from pymongo import ReturnDocument

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)

from app.database import db

from app.dependencies import (
    get_current_user,
)

from app.schemas.agent import (
    AgentCreate,
    AgentResetPin,
    AgentUpdate,
)

from app.services.otp_service import (
    normalize_phone,
)

from app.utils.security import (
    hash_pin,
)


router = APIRouter(
    prefix="/admin",
    tags=["Admin"],
)


# =========================================================
# ADMIN AUTH
# =========================================================

async def require_admin(
    current_user: dict = Depends(
        get_current_user,
    ),
):
    role = str(
        current_user.get(
            "role",
            "",
        )
    ).lower()

    if role != "admin":
        raise HTTPException(
            status_code=(
                status.HTTP_403_FORBIDDEN
            ),
            detail=(
                "Admin access required"
            ),
        )

    if not current_user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=(
                status.HTTP_403_FORBIDDEN
            ),
            detail=(
                "Admin account is disabled"
            ),
        )

    return current_user


# =========================================================
# IMAGE URL
# =========================================================

# =========================================================
# IMAGE URL
# =========================================================

def image_url(
    path: str | None,
) -> str | None:
    if not path:
        return None

    value = (
        str(path)
        .replace("\\", "/")
        .strip()
    )

    if not value:
        return None

    # Already full URL
    if (
        value.startswith("http://")
        or value.startswith("https://")
    ):
        return value

    # Already correct static URL
    if value.startswith("/uploads/"):
        return value

    # Relative path from database:
    # uploads/nid/xxx.jpg
    # uploads/face/xxx.jpg
    if value.startswith("uploads/"):
        return f"/{value}"

    # Absolute path:
    # D:/Mobile_App_Banking/backend/uploads/nid/xxx.jpg
    if "/uploads/" in value:
        relative_path = value.split(
            "/uploads/",
            1,
        )[1]

        return (
            f"/uploads/"
            f"{relative_path}"
        )

    # Fallback
    filename = Path(
        value
    ).name

    if not filename:
        return None

    return (
        f"/uploads/{filename}"
    )

# =========================================================
# USER SERIALIZER
# =========================================================

def serialize_user(
    user: dict,
) -> dict:
    user_id = str(
        user["_id"]
    )

    # =====================================================
    # KYC
    # =====================================================

    kyc = (
        user.get("kyc")
        or {}
    )

    # =====================================================
    # NID DATA
    #
    # Support:
    # NEW: user.kyc.nid_data
    # OLD: user.nid_data
    # =====================================================

    nid_data = (
        kyc.get("nid_data")
        or user.get("nid_data")
        or {}
    )

    # =====================================================
    # FACE MATCH
    #
    # Support:
    # NEW: user.kyc.face_match
    # OLD: user.face_match_result
    # =====================================================

    face_match = (
        kyc.get("face_match")
        or user.get("face_match_result")
        or user.get("face_match")
        or {}
    )

    # =====================================================
    # IMAGES
    #
    # NEW KYC STRUCTURE
    # OLD KYC STRUCTURE
    # =====================================================

    nid_front_path = (
        kyc.get(
            "nid_front_path"
        )
        or user.get(
            "nid_front_path"
        )
        or user.get(
            "nid_image"
        )
        or user.get(
            "nid_image_path"
        )
    )


    nid_back_path = (
        kyc.get(
            "nid_back_path"
        )
        or user.get(
            "nid_back_path"
        )
    )


    nid_face_path = (
        kyc.get(
            "nid_face_path"
        )
        or user.get(
            "nid_face_path"
        )
    )


    selfie_path = (
        kyc.get(
            "selfie_path"
        )
        or user.get(
            "selfie_path"
        )
        or user.get(
            "face_image"
        )
        or user.get(
            "face_image_path"
        )
    )


    # =====================================================
    # IMAGE URLS
    # =====================================================

    nid_front_url = image_url(
        nid_front_path
    )

    nid_back_url = image_url(
        nid_back_path
    )

    nid_face_url = image_url(
        nid_face_path
    )

    selfie_url = image_url(
        selfie_path
    )


    # =====================================================
    # FACE RESULT
    # =====================================================

    match_score = (
        face_match.get(
            "match_score"
        )
    )

    if match_score is None:
        match_score = user.get(
            "match_score"
        )


    distance = (
        face_match.get(
            "distance"
        )
    )

    if distance is None:
        distance = user.get(
            "distance"
        )


    threshold = (
        face_match.get(
            "threshold"
        )
    )

    if threshold is None:
        threshold = user.get(
            "threshold"
        )


    # =====================================================
    # FACE VERIFIED
    # =====================================================

    face_verified = kyc.get(
        "face_verified"
    )

    if face_verified is None:
        face_verified = face_match.get(
            "verified"
        )

    if face_verified is None:
        face_verified = user.get(
            "face_verified"
        )


    # =====================================================
    # NID INFORMATION
    # =====================================================

    nid_number = (
        nid_data.get(
            "nid_number"
        )
        or nid_data.get(
            "id_number"
        )
        or ""
    )


    nid_first_name = (
        nid_data.get("first_name")
        or kyc.get("first_name")
        or user.get("first_name")
        or ""
    )

    nid_last_name = (
        nid_data.get("last_name")
        or kyc.get("last_name")
        or user.get("last_name")
        or ""
    )

    full_name = (
        nid_data.get("full_name")
        or kyc.get("full_name")
        or (
            f"{nid_first_name} {nid_last_name}"
        ).strip()
    )

    date_of_birth = (
        nid_data.get("date_of_birth")
        or nid_data.get("dob")
        or kyc.get("date_of_birth")
        or user.get("date_of_birth")
        or ""
    )

    expiry_date = (
        nid_data.get("expiry_date")
        or nid_data.get("expiration_date")
        or kyc.get("expiry_date")
        or user.get("expiry_date")
        or ""
    )

    gender = (
        nid_data.get("gender")
        or kyc.get("gender")
        or user.get("gender")
        or ""
    )

    address = (
        nid_data.get("address")
        or kyc.get("address")
        or user.get("address")
        or ""
    )

    source = (
        nid_data.get("source")
        or kyc.get("source")
        or (
            "legacy"
            if (user.get("nid_image") or user.get("nid_front_path"))
            else ""
        )
    )


    # =====================================================
    # OTHER KYC DATA
    # =====================================================

    nid_confirmed = (
        kyc.get(
            "nid_confirmed"
        )
    )

    if nid_confirmed is None:
        nid_confirmed = user.get(
            "nid_confirmed",
            False,
        )


    face_attempts = (
        kyc.get(
            "face_attempts"
        )
    )

    if face_attempts is None:
        face_attempts = user.get(
            "face_attempts",
            0,
        )


    manual_review_required = bool(
        kyc.get(
            "manual_review_required",
            user.get(
                "manual_review_required",
                False,
            ),
        )
    )


    admin_review = (
        kyc.get(
            "admin_review"
        )
        or user.get(
            "admin_review"
        )
        or ""
    )


    # =====================================================
    # RESPONSE
    # =====================================================

    return {
        "_id":
            user_id,

        "id":
            user_id,

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
            user.get(
                "phone_number",
                "",
            ),

        "role":
            user.get(
                "role",
                "user",
            ),

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
            user.get(
                "kyc_status",
                "not_submitted",
            ),

        "created_at":
            user.get(
                "created_at"
            ),

        "updated_at":
            user.get(
                "updated_at"
            ),

        # =================================================
        # NESTED KYC
        # For UserKycDetail.jsx
        # =================================================

        "kyc": {
            "status":
                user.get(
                    "kyc_status",
                    "not_submitted",
                ),

            "admin_review":
                admin_review,

            # ---------------------------------------------
            # NID INFORMATION
            # ---------------------------------------------

            "nid_number":
                nid_number,

            "first_name":
                nid_first_name,

            "last_name":
                nid_last_name,

            "full_name":
                full_name,

            "date_of_birth":
                date_of_birth,

            "expiry_date":
                expiry_date,

            "gender":
                gender,

            "address":
                address,

            "source":
                source,

            # ---------------------------------------------
            # IMAGE PATHS
            # ---------------------------------------------

            "nid_front_path":
                nid_front_path,

            "nid_back_path":
                nid_back_path,

            "nid_face_path":
                nid_face_path,

            "selfie_path":
                selfie_path,

            # ---------------------------------------------
            # IMAGE URLS
            # ---------------------------------------------

            "nid_front_url":
                nid_front_url,

            "nid_back_url":
                nid_back_url,

            "nid_face_url":
                nid_face_url,

            "selfie_url":
                selfie_url,

            # ---------------------------------------------
            # FACE VERIFICATION
            # ---------------------------------------------

            "face_verified":
                face_verified,

            "face_match":
                face_match,

            "face_match_score":
                match_score,

            "match_score":
                match_score,

            "distance":
                distance,

            "threshold":
                threshold,

            "model":
                face_match.get(
                    "model"
                ),

            "similarity_metric":
                face_match.get(
                    "similarity_metric"
                ),

            "manual_review_required":
                manual_review_required,

            "face_attempts":
                face_attempts,

            "nid_confirmed":
                bool(
                    nid_confirmed
                ),

            "created_at":
                kyc.get(
                    "created_at"
                ),

            "updated_at":
                kyc.get(
                    "updated_at"
                ),
        },

        # =================================================
        # FLAT FIELDS
        # Keep old frontend compatibility
        # =================================================

        "nid_data": {
            "nid_number":
                nid_number,

            "first_name":
                nid_first_name,

            "last_name":
                nid_last_name,

            "full_name":
                full_name,

            "date_of_birth":
                date_of_birth,

            "expiry_date":
                expiry_date,

            "gender":
                gender,

            "address":
                address,

            "source":
                source,
        },

        "nid_front_path":
            nid_front_path,

        "nid_back_path":
            nid_back_path,

        "nid_face_path":
            nid_face_path,

        "selfie_path":
            selfie_path,

        "nid_front_url":
            nid_front_url,

        "nid_back_url":
            nid_back_url,

        "nid_face_url":
            nid_face_url,

        "selfie_url":
            selfie_url,

        # OLD naming compatibility

        "nid_image":
            nid_front_url,

        "nid_image_path":
            nid_front_url,

        "face_image":
            selfie_url,

        "face_image_path":
            selfie_url,

        # FACE

        "face_verified":
            face_verified,

        "face_match":
            face_match,

        "face_match_result":
            face_match,

        "match_result":
            face_match,

        "match_score":
            match_score,

        "distance":
            distance,

        "threshold":
            threshold,

        "face_attempts":
            face_attempts,

        "nid_confirmed":
            bool(
                nid_confirmed
            ),

        "manual_review_required":
            manual_review_required,
    }
# =========================================================
# LIST CUSTOMERS
# =========================================================

@router.get("/users")
async def list_users(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    results = []

    cursor = (
        db["users"]
        .find(
            {
                "role":
                    "user",
            },
            {
                "pin": 0,
                "otp_hash": 0,
                "otp_code": 0,
                "otp_expiry": 0,
                "otp_attempts": 0,
            },
        )
        .sort(
            "created_at",
            -1,
        )
    )

    async for user in cursor:
        user_data = (
            serialize_user(
                user
            )
        )

        user_id = str(
            user["_id"]
        )

        account = await db[
            "accounts"
        ].find_one(
            {
                "user_id":
                    user_id,
            }
        )

        if account:
            user_data[
                "balance"
            ] = float(
                account.get(
                    "balance",
                    0,
                )
            )

            user_data[
                "currency"
            ] = account.get(
                "currency",
                "USD",
            )

        else:
            user_data[
                "balance"
            ] = 0.0

            user_data[
                "currency"
            ] = "USD"

        results.append(
            user_data
        )

    return {
        "success":
            True,

        "count":
            len(results),

        "data":
            results,
    }


# =========================================================
# GET CUSTOMER DETAIL
# =========================================================

@router.get(
    "/users/{user_id}"
)
async def get_user_detail(
    user_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            user_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid user ID format"
            ),
        ) from error

    user = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "user",
        },
        {
            "pin": 0,
            "otp_hash": 0,
            "otp_code": 0,
            "otp_expiry": 0,
            "otp_attempts": 0,
        },
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail=(
                "User not found"
            ),
        )

    result = serialize_user(
        user
    )

    # =====================================
    # CUSTOMER ACCOUNT
    # =====================================

    account = await db[
        "accounts"
    ].find_one(
        {
            "user_id":
                user_id,
        }
    )

    if account:
        result[
            "balance"
        ] = float(
            account.get(
                "balance",
                0,
            )
        )

        result[
            "currency"
        ] = account.get(
            "currency",
            "USD",
        )

    else:
        result[
            "balance"
        ] = 0.0

        result[
            "currency"
        ] = "USD"

    # =====================================
    # TRANSACTION COUNT
    # =====================================

    result[
        "total_transactions"
    ] = await db[
        "transactions"
    ].count_documents(
        {
            "user_id":
                user_id,
        }
    )

    return {
        "success":
            True,

        "data":
            result,
    }

# =========================================================
# ENABLE / DISABLE CUSTOMER
# =========================================================

@router.patch(
    "/users/{user_id}/status"
)
async def change_user_status(
    user_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            user_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid user ID"
            ),
        ) from error

    user = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "user",
        }
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail=(
                "User not found"
            ),
        )

    current_status = user.get(
        "is_active",
        True,
    )

    new_status = (
        not current_status
    )

    await db[
        "users"
    ].update_one(
        {
            "_id":
                object_id,
        },
        {
            "$set": {
                "is_active":
                    new_status,

                "updated_at":
                    datetime.now(
                        timezone.utc
                    ),
            }
        },
    )

    return {
        "success":
            True,

        "message": (
            "User enabled successfully"
            if new_status
            else
            "User disabled successfully"
        ),

        "is_active":
            new_status,
    }


# =========================================================
# APPROVE CUSTOMER KYC
# =========================================================

@router.post(
    "/kyc/{user_id}/approve"
)
async def approve_kyc(
    user_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            user_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid user ID format"
            ),
        ) from error

    user = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "user",
        }
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail=(
                "User not found"
            ),
        )

    current_status = user.get(
        "kyc_status",
        "not_submitted",
    )

    if current_status == (
        "approved"
    ):
        raise HTTPException(
            status_code=400,
            detail={
                "message":
                    "KYC is already approved",

                "kyc_status":
                    current_status,
            },
        )

    now = datetime.now(
        timezone.utc
    )

    await db[
        "users"
    ].update_one(
        {
            "_id":
                object_id,
        },
        {
            "$set": {
                "kyc_status":
                    "approved",

                "is_verified":
                    True,

                "kyc.admin_review":
                    "approved",

                "kyc.manual_review_required":
                    False,

                "updated_at":
                    now,
            }
        },
    )

    return {
        "success": True,

        "message":
            "KYC approved successfully",

        "previous_status":
            current_status,

        "kyc_status":
            "approved",
    }


# =========================================================
# REJECT CUSTOMER KYC
# =========================================================

@router.post(
    "/kyc/{user_id}/reject"
)
async def reject_kyc(
    user_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            user_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid user ID format"
            ),
        ) from error

    user = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "user",
        }
    )

    if not user:
        raise HTTPException(
            status_code=404,
            detail=(
                "User not found"
            ),
        )

    current_status = user.get(
        "kyc_status",
        "not_submitted",
    )

    if current_status == (
        "rejected"
    ):
        raise HTTPException(
            status_code=400,
            detail={
                "message":
                    "KYC is already rejected",

                "kyc_status":
                    current_status,
            },
        )

    now = datetime.now(
        timezone.utc
    )

    await db[
        "users"
    ].update_one(
        {
            "_id":
                object_id,
        },
        {
            "$set": {
                "kyc_status":
                    "rejected",

                "is_verified":
                    False,

                "kyc.admin_review":
                    "rejected",

                "kyc.manual_review_required":
                    False,

                "kyc.face_verified":
                    False,

                "updated_at":
                    now,
            }
        },
    )

    return {
        "success":
            True,

        "message":
            "KYC rejected successfully",

        "previous_status":
            current_status,

        "kyc_status":
            "rejected",
    }


# =========================================================
# LIST AGENTS
# =========================================================

@router.get("/agents")
async def list_agents(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    agents = []

    cursor = (
        db["users"]
        .find(
            {
                "role": "agent",
            },
            {
                "pin": 0,
                "otp_hash": 0,
                "otp_code": 0,
                "otp_expiry": 0,
            },
        )
        .sort(
            "created_at",
            -1,
        )
    )

    async for agent in cursor:
        agent_id = str(
            agent["_id"]
        )

        # =====================================
        # AGENT WALLET
        # =====================================

        agent_wallet = await db[
            "agent_wallets"
        ].find_one(
            {
                "agent_id":
                    agent_id,
            }
        )

        agent_balance = (
            float(
                agent_wallet.get(
                    "balance",
                    0,
                )
            )
            if agent_wallet
            else 0.0
        )

        agent_currency = (
            agent_wallet.get(
                "currency",
                "USD",
            )
            if agent_wallet
            else "USD"
        )

        # =====================================
        # AGENT TRANSACTION COUNT
        # =====================================

        total_transactions = (
            await db[
                "transactions"
            ].count_documents(
                {
                    "agent_id":
                        agent_id,

                    "type":
                        "deposit",

                    "status":
                        "success",
                }
            )
        )

        # =====================================
        # AGENT TOTAL DEPOSIT
        # =====================================


        pipeline = [
            {
                "$match": {
                    "agent_id":
                        agent_id,

                    "type":
                        "deposit",

                    "status":
                        "success",
                }
            },
            {
                "$group": {
                    "_id":
                        None,

                    "total": {
                        "$sum":
                            "$amount",
                    },
                }
            },
        ]

        total_deposit = 0.0

        async for stats in db[
            "transactions"
        ].aggregate(
            pipeline
        ):
            total_deposit = float(
                stats.get(
                    "total",
                    0,
                )
            )

        # =====================================
        # RESPONSE
        # =====================================

        agents.append(
            {
                "id":
                    agent_id,

                "_id":
                    agent_id,

                "first_name":
                    agent.get(
                        "first_name",
                        "",
                    ),

                "last_name":
                    agent.get(
                        "last_name",
                        "",
                    ),

                "phone_number":
                    agent.get(
                        "phone_number",
                        "",
                    ),

                "role":
                    "agent",

                "agent_code":
                    agent.get(
                        "agent_code",
                        "",
                    ),

                "branch_name":
                    agent.get(
                        "branch_name",
                        "",
                    ),

                # NEW
                "balance":
                    agent_balance,

                "currency":
                    agent_currency,

                "is_active":
                    agent.get(
                        "is_active",
                        True,
                    ),

                "is_verified":
                    agent.get(
                        "is_verified",
                        True,
                    ),

                "kyc_status":
                    agent.get(
                        "kyc_status",
                        "not_required",
                    ),

                "total_transactions":
                    total_transactions,

                "total_deposit":
                    total_deposit,

                "created_at":
                    agent.get(
                        "created_at"
                    ),

                "updated_at":
                    agent.get(
                        "updated_at"
                    ),
            }
        )

    return {
        "success":
            True,

        "count":
            len(
                agents
            ),

        "data":
            agents,
    }
# =========================================================
# CREATE AGENT
# =========================================================

@router.post(
    "/agents",
    status_code=201,
)
async def create_agent(
    payload: AgentCreate,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    first_name = (
        payload.first_name
        .strip()
    )

    last_name = (
        payload.last_name
        .strip()
    )

    phone = normalize_phone(
        payload.phone_number
    )

    pin = (
        payload.pin
        .strip()
    )

    agent_code = (
        payload.agent_code
        .strip()
        .upper()
    )

    # =====================================================
    # VALIDATE PIN
    # =====================================================

    if (
        len(pin) != 6
        or not pin.isdigit()
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "PIN must contain exactly 6 digits"
            ),
        )

    # =====================================================
    # CHECK PHONE
    # =====================================================

    existing_phone = await db[
        "users"
    ].find_one(
        {
            "phone_number":
                phone,
        }
    )

    if existing_phone:
        raise HTTPException(
            status_code=409,
            detail=(
                "Phone number already registered"
            ),
        )

    # =====================================================
    # CHECK AGENT CODE
    # =====================================================

    existing_code = await db[
        "users"
    ].find_one(
        {
            "agent_code":
                agent_code,
        }
    )

    if existing_code:
        raise HTTPException(
            status_code=409,
            detail=(
                "Agent code already exists"
            ),
        )

    # =====================================================
    # CHECK NID NUMBER
    # =====================================================

    existing_nid = await db[
        "users"
    ].find_one(
        {
            "nid_number":
                payload.nid_number
                .strip(),
        }
    )

    if existing_nid:
        raise HTTPException(
            status_code=409,
            detail=(
                "National ID number already exists"
            ),
        )

    now = datetime.now(
        timezone.utc
    )

    # =====================================================
    # CREATE AGENT
    # =====================================================

    agent_document = {
        "first_name":
            first_name,

        "last_name":
            last_name,

        "phone_number":
            phone,

        "nid_number":
            payload.nid_number
            .strip(),

        "date_of_birth":
            payload.date_of_birth
            .isoformat(),

        "gender":
            payload.gender,

        "address":
            payload.address
            .strip(),

        "agent_code":
            agent_code,

        "branch_name":
            payload.branch_name
            .strip(),

        "daily_transaction_limit": (
            float(payload.daily_transaction_limit)
            if payload.daily_transaction_limit is not None
            else None
        ),

        "pin":
            hash_pin(
                pin
            ),

        "role":
            "agent",

        "is_active":
            True,

        "is_verified":
            True,

        "kyc_status":
            "not_required",

        "created_by":
            str(
                current_admin[
                    "_id"
                ]
            ),

        "created_at":
            now,

        "updated_at":
            now,
    }

    result = await db[
        "users"
    ].insert_one(
        agent_document
    )

    agent_id = str(
        result.inserted_id
    )

    # =====================================================
    # CREATE AGENT WALLET
    # =====================================================

    wallet_document = {
        "agent_id":
            agent_id,

        "balance":
            0.0,

        "currency":
            "USD",

        "is_frozen":
            False,

        "created_at":
            now,

        "updated_at":
            now,
    }

    try:
        await db[
            "agent_wallets"
        ].insert_one(
            wallet_document
        )

    except Exception as error:

        # rollback agent if wallet fails
        await db[
            "users"
        ].delete_one(
            {
                "_id":
                    result.inserted_id,
            }
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to create agent wallet"
            ),
        ) from error

    # =====================================================
    # RESPONSE
    # =====================================================

    return {
        "success":
            True,

        "message":
            "Agent account created successfully",

        "data": {
            "id":
                agent_id,

            "first_name":
                first_name,

            "last_name":
                last_name,

            "phone_number":
                phone,

            "nid_number":
                payload.nid_number
                .strip(),

            "date_of_birth":
                payload.date_of_birth
                .isoformat(),

            "gender":
                payload.gender,

            "address":
                payload.address
                .strip(),

            "agent_code":
                agent_code,

            "branch_name":
                payload.branch_name
                .strip(),

            "daily_transaction_limit": (
                float(payload.daily_transaction_limit)
                if payload.daily_transaction_limit is not None
                else None
            ),

            "balance":
                0.0,

            "currency":
                "USD",

            "role":
                "agent",

            "is_active":
                True,

            "is_verified":
                True,

            "kyc_status":
                "not_required",

            "created_at":
                now,
        },
    }

# =========================================================
# GET AGENT DETAIL
# =========================================================

@router.get(
    "/agents/{agent_id}"
)
async def get_agent(
    agent_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            agent_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid agent ID"
            ),
        ) from error

    agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "agent",
        },
        {
            "pin": 0,
            "otp_hash": 0,
        },
    )

    if not agent:
        raise HTTPException(
            status_code=404,
            detail=(
                "Agent not found"
            ),
        )

    agent_id_string = str(
        agent["_id"]
    )

    total_transactions = (
        await db[
            "transactions"
        ].count_documents(
            {
                "agent_id":
                    agent_id_string,

                "type":
                    "deposit",
            }
        )
    )

    pipeline = [
        {
            "$match": {
                "agent_id":
                    agent_id_string,

                "type":
                    "deposit",

                "status":
                    "success",
            }
        },
        {
            "$group": {
                "_id":
                    None,

                "total": {
                    "$sum":
                        "$amount"
                },
            }
        },
    ]

    total_deposit = 0.0

    async for stats in db[
        "transactions"
    ].aggregate(
        pipeline
    ):
        total_deposit = float(
            stats.get(
                "total",
                0,
            )
        )

    return {
        "success":
            True,

        "data": {
            "id":
                agent_id_string,

            "first_name":
                agent.get(
                    "first_name",
                    "",
                ),

            "last_name":
                agent.get(
                    "last_name",
                    "",
                ),

            "phone_number":
                agent.get(
                    "phone_number",
                    "",
                ),

            "role":
                "agent",

            "is_active":
                agent.get(
                    "is_active",
                    True,
                ),

            "is_verified":
                agent.get(
                    "is_verified",
                    True,
                ),

            "kyc_status":
                agent.get(
                    "kyc_status",
                    "not_required",
                ),

            "total_transactions":
                total_transactions,

            "total_deposit":
                total_deposit,

            "created_at":
                agent.get(
                    "created_at"
                ),

            "updated_at":
                agent.get(
                    "updated_at"
                ),
        },
    }


# =========================================================
# UPDATE AGENT
# =========================================================

@router.put(
    "/agents/{agent_id}"
)
async def update_agent(
    agent_id: str,

    payload: AgentUpdate,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            agent_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid agent ID"
            ),
        ) from error

    agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "agent",
        }
    )

    if not agent:
        raise HTTPException(
            status_code=404,
            detail=(
                "Agent not found"
            ),
        )

    update_data = {}

    # =====================================
    # First name
    # =====================================

    if (
        payload.first_name
        is not None
    ):
        first_name = (
            payload.first_name
            .strip()
        )

        if not first_name:
            raise HTTPException(
                status_code=400,
                detail=(
                    "First name cannot be empty"
                ),
            )

        update_data[
            "first_name"
        ] = first_name

    # =====================================
    # Last name
    # =====================================

    if (
        payload.last_name
        is not None
    ):
        last_name = (
            payload.last_name
            .strip()
        )

        if not last_name:
            raise HTTPException(
                status_code=400,
                detail=(
                    "Last name cannot be empty"
                ),
            )

        update_data[
            "last_name"
        ] = last_name

    # =====================================
    # Phone
    # =====================================

    if (
        payload.phone_number
        is not None
    ):
        phone = normalize_phone(
            payload.phone_number
        )

        duplicate = await db[
            "users"
        ].find_one(
            {
                "phone_number":
                    phone,

                "_id": {
                    "$ne":
                        object_id,
                },
            }
        )

        if duplicate:
            raise HTTPException(
                status_code=409,
                detail=(
                    "Phone number already "
                    "registered"
                ),
            )

        update_data[
            "phone_number"
        ] = phone

    if payload.daily_transaction_limit is not None:
        update_data["daily_transaction_limit"] = float(payload.daily_transaction_limit)

    if not update_data:
        raise HTTPException(
            status_code=400,
            detail=(
                "Nothing to update"
            ),
        )

    update_data[
        "updated_at"
    ] = datetime.now(
        timezone.utc
    )

    await db[
        "users"
    ].update_one(
        {
            "_id":
                object_id,
        },
        {
            "$set":
                update_data,
        },
    )

    updated_agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,
        },
        {
            "pin": 0,
        },
    )

    return {
        "success":
            True,

        "message":
            "Agent updated successfully",

        "data": {
            "id":
                str(
                    updated_agent[
                        "_id"
                    ]
                ),

            "first_name":
                updated_agent.get(
                    "first_name",
                    "",
                ),

            "last_name":
                updated_agent.get(
                    "last_name",
                    "",
                ),

            "phone_number":
                updated_agent.get(
                    "phone_number",
                    "",
                ),

            "role":
                "agent",

            "is_active":
                updated_agent.get(
                    "is_active",
                    True,
                ),
        },
    }


# =========================================================
# RESET AGENT PIN
# =========================================================

@router.patch(
    "/agents/{agent_id}/pin"
)
async def reset_agent_pin(
    agent_id: str,

    payload: AgentResetPin,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            agent_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid agent ID"
            ),
        ) from error

    agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "agent",
        }
    )

    if not agent:
        raise HTTPException(
            status_code=404,
            detail=(
                "Agent not found"
            ),
        )

    pin = payload.pin.strip()

    if (
        len(pin) != 6
        or not pin.isdigit()
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "PIN must contain "
                "exactly 6 digits"
            ),
        )

    await db[
        "users"
    ].update_one(
        {
            "_id":
                object_id,
        },
        {
            "$set": {
                "pin":
                    hash_pin(
                        pin
                    ),

                "updated_at":
                    datetime.now(
                        timezone.utc
                    ),
            }
        },
    )

    return {
        "success":
            True,

        "message":
            "Agent PIN reset successfully",
    }


# =========================================================
# ENABLE / DISABLE AGENT
# =========================================================

@router.patch(
    "/agents/{agent_id}/status"
)
async def change_agent_status(
    agent_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            agent_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid agent ID"
            ),
        ) from error

    agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "agent",
        }
    )

    if not agent:
        raise HTTPException(
            status_code=404,
            detail=(
                "Agent not found"
            ),
        )

    current_status = agent.get(
        "is_active",
        True,
    )

    new_status = (
        not current_status
    )

    await db[
        "users"
    ].update_one(
        {
            "_id":
                object_id,
        },
        {
            "$set": {
                "is_active":
                    new_status,

                "updated_at":
                    datetime.now(
                        timezone.utc
                    ),
            },
        },
    )

    return {
        "success":
            True,

        "message": (
            "Agent enabled successfully"
            if new_status
            else
            "Agent disabled successfully"
        ),

        "is_active":
            new_status,
    }


# =========================================================
# DELETE AGENT
# =========================================================

@router.delete(
    "/agents/{agent_id}"
)
async def delete_agent(
    agent_id: str,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        object_id = ObjectId(
            agent_id
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid agent ID"
            ),
        ) from error

    agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                object_id,

            "role":
                "agent",
        }
    )

    if not agent:
        raise HTTPException(
            status_code=404,
            detail=(
                "Agent not found"
            ),
        )

    # =====================================
    # Don't delete Agent with transaction
    # history.
    # =====================================

    has_transaction = await db[
        "transactions"
    ].find_one(
        {
            "agent_id":
                agent_id,
        }
    )

    if has_transaction:
        raise HTTPException(
            status_code=400,
            detail=(
                "This agent has transaction "
                "history. Disable the agent "
                "instead of deleting it."
            ),
        )

    await db[
        "users"
    ].delete_one(
        {
            "_id":
                object_id,

            "role":
                "agent",
        }
    )

    return {
        "success":
            True,

        "message":
            "Agent deleted successfully",
    }


# =========================================================
# ADMIN GET ALL AGENT DEPOSIT TRANSACTIONS
# =========================================================

@router.get(
    "/agent-transactions"
)
async def get_agent_transactions(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    cursor = (
        db[
            "transactions"
        ]
        .find(
            {
                "type":
                    "deposit",

                "deposit_source":
                    "agent_cash",

                "agent_id": {
                    "$exists":
                        True,
                },
            }
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(
            200
        )
    )

    results = []

    async for transaction in cursor:
        results.append(
            {
                "id":
                    str(
                        transaction[
                            "_id"
                        ]
                    ),

                "transaction_id":
                    transaction.get(
                        "transaction_id",
                        "",
                    ),

                "customer_id":
                    transaction.get(
                        "customer_id",
                        "",
                    ),

                "customer_name":
                    transaction.get(
                        "customer_name",
                        "",
                    ),

                "customer_phone":
                    transaction.get(
                        "customer_phone",
                        "",
                    ),

                "agent_id":
                    transaction.get(
                        "agent_id",
                        "",
                    ),

                "agent_name":
                    transaction.get(
                        "agent_name",
                        "",
                    ),

                "amount":
                    float(
                        transaction.get(
                            "amount",
                            0,
                        )
                    ),

                "currency":
                    transaction.get(
                        "currency",
                        "USD",
                    ),

                "balance_before":
                    float(
                        transaction.get(
                            "balance_before",
                            0,
                        )
                    ),

                "balance_after":
                    float(
                        transaction.get(
                            "balance_after",
                            0,
                        )
                    ),

                "status":
                    transaction.get(
                        "status",
                        "",
                    ),

                "description":
                    transaction.get(
                        "description",
                        "",
                    ),

                "created_at":
                    transaction.get(
                        "created_at"
                    ),
            }
        )

    return {
        "success":
            True,

        "count":
            len(results),

        "data":
            results,
    }
