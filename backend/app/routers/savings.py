from datetime import (
    datetime,
    timezone,
)
from decimal import Decimal, ROUND_HALF_UP
from uuid import uuid4
from bson import ObjectId
from pymongo import ReturnDocument
from dateutil.relativedelta import relativedelta

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
from app.schemas.savings_schema import (
    SavingsTermCreate,
    SavingsTermUpdate,
    SavingsGlobalSettingsUpdate,
    SavingsOpenRequest,
    SavingsRateSettings,
    SavingsDepositCreate,
)

router = APIRouter(
    tags=["Savings"],
)

SAVINGS_TERMS_COLLECTION = "savings_terms"
SAVINGS_SETTINGS_COLLECTION = "savings_settings"
SAVINGS_COLLECTION = "savings"
SAVINGS_AUDIT_COLLECTION = "savings_rate_audits"

DEFAULT_GLOBAL_SETTINGS = {
    "_id": "savings",
    "min_deposit": 5.0,
    "max_months": 48,
}

DEFAULT_TERMS = [
    {
        "label": "1 Month",
        "months": 1,
        "rate": 0.005,  # 0.5% per month
        "rate_unit": "monthly",
        "min_amount": None,
        "active": True,
        "sort": 1,
    },
    {
        "label": "3 Months",
        "months": 3,
        "rate": 0.0055,  # 0.55% per month
        "rate_unit": "monthly",
        "min_amount": None,
        "active": True,
        "sort": 2,
    },
    {
        "label": "6 Months",
        "months": 6,
        "rate": 0.0065,  # 0.65% per month
        "rate_unit": "monthly",
        "min_amount": None,
        "active": True,
        "sort": 3,
    },
    {
        "label": "1 Year",
        "months": 12,
        "rate": 0.015,  # 1.5% annual
        "rate_unit": "annual",
        "min_amount": None,
        "active": True,
        "sort": 4,
    },
    {
        "label": "2 Years",
        "months": 24,
        "rate": 0.020,  # 2.0% annual
        "rate_unit": "annual",
        "min_amount": None,
        "active": True,
        "sort": 5,
    },
    {
        "label": "3 Years",
        "months": 36,
        "rate": 0.023,  # 2.3% annual
        "rate_unit": "annual",
        "min_amount": None,
        "active": True,
        "sort": 6,
    },
]


# =========================================================
# HELPERS & SEEDING
# =========================================================

async def get_or_create_settings() -> dict:
    """Load or initialize global savings settings doc {_id: 'savings', min_deposit, max_months}."""
    settings = await db[SAVINGS_SETTINGS_COLLECTION].find_one({"_id": "savings"})
    if not settings:
        # Check if there is an old settings doc without _id='savings'
        old_doc = await db[SAVINGS_SETTINGS_COLLECTION].find_one({})
        now = datetime.now(timezone.utc)
        if old_doc:
            settings = {
                "_id": "savings",
                "min_deposit": float(old_doc.get("min_deposit", 5.0)),
                "max_months": int(old_doc.get("max_months", 48)),
                "created_at": old_doc.get("created_at", now),
                "updated_at": now,
            }
        else:
            settings = {
                **DEFAULT_GLOBAL_SETTINGS,
                "created_at": now,
                "updated_at": now,
            }
        await db[SAVINGS_SETTINGS_COLLECTION].update_one(
            {"_id": "savings"},
            {"$set": settings},
            upsert=True,
        )
    return settings


async def ensure_seeded_terms():
    """Seed the savings_terms collection with sensible defaults only if it is empty."""
    count = await db[SAVINGS_TERMS_COLLECTION].count_documents({})
    if count == 0:
        now = datetime.now(timezone.utc)
        seed_docs = [
            {
                **item,
                "created_at": now,
                "updated_at": now,
            }
            for item in DEFAULT_TERMS
        ]
        await db[SAVINGS_TERMS_COLLECTION].insert_many(seed_docs)


def require_customer(current_user: dict):
    role = str(current_user.get("role", "user")).lower()
    if role != "user":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Customer access required",
        )
    if not current_user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account is disabled",
        )
    return current_user


def require_admin(current_user: dict):
    role = str(current_user.get("role", "")).lower()
    if role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    if not current_user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin account is disabled",
        )
    return current_user


def generate_saving_id() -> str:
    return f"SAV-{uuid4().hex[:10].upper()}"


# =========================================================
# INTEREST FORMULA & DATE CALCULATION (SERVER SIDE)
# =========================================================

def calculate_interest(principal: float, rate: float, months: int, rate_unit: str) -> tuple[float, float]:
    """
    Server-side Interest Formula:
      - rate_unit 'annual':  interest = principal * rate * months / 12
      - rate_unit 'monthly': interest = principal * rate * months
      - Round to 2 decimals only at the end.
    Returns: (interest_amount, total_payout)
    """
    p_dec = Decimal(str(principal))
    r_dec = Decimal(str(rate))
    m_dec = Decimal(str(months))

    if rate_unit == "annual":
        interest_dec = (p_dec * r_dec * m_dec / Decimal("12")).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )
    else:  # monthly
        interest_dec = (p_dec * r_dec * m_dec).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )

    interest_amount = float(interest_dec)
    total_payout = float((p_dec + interest_dec).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))
    return interest_amount, total_payout


def calculate_maturity_date(start_date: datetime, months: int) -> datetime:
    """Calculates maturity_date = start + relativedelta(months=months)."""
    return start_date + relativedelta(months=months)


async def compute_term_warnings() -> list[str]:
    """
    Non-blocking warnings:
    If any longer-duration active term has a LOWER annual-equivalent rate than a shorter active term,
    show which terms conflict (e.g. '6 Months (7.80% p.a.) is higher than 1 Year (1.50% p.a.)').
    Compute annual equivalent as rate*12 for monthly and rate for annual.
    """
    cursor = db[SAVINGS_TERMS_COLLECTION].find({"active": True}).sort([("months", 1), ("sort", 1)])
    active_terms = await cursor.to_list(100)
    warnings = []

    for i in range(len(active_terms)):
        t_i = active_terms[i]
        r_i = float(t_i.get("rate", 0.0))
        unit_i = t_i.get("rate_unit", "annual")
        eff_annual_i = r_i if unit_i == "annual" else r_i * 12
        m_i = int(t_i.get("months", 1))

        for j in range(i + 1, len(active_terms)):
            t_j = active_terms[j]
            r_j = float(t_j.get("rate", 0.0))
            unit_j = t_j.get("rate_unit", "annual")
            eff_annual_j = r_j if unit_j == "annual" else r_j * 12
            m_j = int(t_j.get("months", 1))

            if m_j > m_i and eff_annual_j < eff_annual_i:
                msg = (
                    f"{t_i.get('label')} ({eff_annual_i * 100:.2f}% p.a.) "
                    f"is higher than {t_j.get('label')} ({eff_annual_j * 100:.2f}% p.a.)"
                )
                if msg not in warnings:
                    warnings.append(msg)

    return warnings


async def validate_term_fields(
    months: int,
    rate: float,
    rate_unit: str,
    min_amount: float | None,
    max_months: int,
    active: bool = True,
    exclude_id: str | None = None,
):
    """
    Validation:
      - months is an integer, 1 <= months <= max_months.
      - no two ACTIVE terms with the same months.
      - rate > 0 and rate <= 0.30 for annual (or <= 0.03 for monthly).
      - min amounts > 0.
    """
    if months < 1 or months > max_months:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Duration months must be between 1 and {max_months} months.",
        )

    if rate_unit == "annual":
        if rate <= 0 or rate > 0.30:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Annual interest rate must be > 0 and <= 0.30 (max 30% p.a.).",
            )
    elif rate_unit == "monthly":
        if rate <= 0 or rate > 0.03:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Monthly interest rate must be > 0 and <= 0.03 (max 3% per month).",
            )
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="rate_unit must be either 'annual' or 'monthly'.",
        )

    if min_amount is not None and min_amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Minimum deposit amount must be greater than $0.00.",
        )

    if active:
        query = {"months": months, "active": True}
        if exclude_id and ObjectId.is_valid(exclude_id):
            query["_id"] = {"$ne": ObjectId(exclude_id)}
        existing = await db[SAVINGS_TERMS_COLLECTION].find_one(query)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"An active savings term with {months} months already exists ('{existing.get('label')}').",
            )


async def write_audit_log(admin_id: str, action: str, old_value: dict | None, new_value: dict | None):
    """Write an audit log on every change (admin_id, action, old value, new value, timestamp)."""
    now = datetime.now(timezone.utc)
    await db[SAVINGS_AUDIT_COLLECTION].insert_one({
        "admin_id": str(admin_id),
        "action": action,
        "old_value": old_value or {},
        "new_value": new_value or {},
        "timestamp": now,
        "created_at": now,
    })


# =========================================================
# ADMIN ENDPOINTS (FULL CONTROL OF TERMS AND SETTINGS)
# =========================================================

@router.get("/admin/savings/terms")
async def admin_get_all_terms(
    current_admin: dict = Depends(get_current_user),
):
    """
    GET /admin/savings/terms
    Admin retrieves all terms (including inactive), sorted by sort asc, months asc.
    Includes effective annual/monthly equivalents and non-blocking warnings.
    """
    require_admin(current_admin)
    await ensure_seeded_terms()
    settings = await get_or_create_settings()
    global_min = float(settings.get("min_deposit", 5.0))

    cursor = db[SAVINGS_TERMS_COLLECTION].find({}).sort([("sort", 1), ("months", 1)])
    terms_list = await cursor.to_list(100)

    formatted_terms = []
    for t in terms_list:
        rate = float(t.get("rate", 0.0))
        unit = t.get("rate_unit", "annual")
        annual_eq = rate if unit == "annual" else round(rate * 12, 6)
        monthly_eq = round(rate / 12, 6) if unit == "annual" else rate
        min_amt = float(t.get("min_amount")) if t.get("min_amount") is not None else global_min

        formatted_terms.append({
            "id": str(t["_id"]),
            "label": t.get("label", ""),
            "months": int(t.get("months", 1)),
            "rate": rate,
            "rate_unit": unit,
            "annual_equivalent": annual_eq,
            "monthly_equivalent": monthly_eq,
            "min_amount": min_amt,
            "active": bool(t.get("active", True)),
            "sort": int(t.get("sort", 0)),
            "created_at": t.get("created_at").isoformat() if t.get("created_at") else None,
            "updated_at": t.get("updated_at").isoformat() if t.get("updated_at") else None,
        })

    warnings = await compute_term_warnings()

    return {
        "success": True,
        "data": {
            "terms": formatted_terms,
            "settings": {
                "min_deposit": global_min,
                "max_months": int(settings.get("max_months", 48)),
            },
            "warnings": warnings,
        },
    }


@router.post("/admin/savings/terms", status_code=status.HTTP_201_CREATED)
async def admin_create_term(
    payload: SavingsTermCreate,
    current_admin: dict = Depends(get_current_user),
):
    """
    POST /admin/savings/terms
    Creates a new savings term. Validates months, rates, and uniqueness of active months.
    Writes audit log.
    """
    require_admin(current_admin)
    admin_id = str(current_admin.get("_id", "admin"))
    settings = await get_or_create_settings()
    max_months = int(settings.get("max_months", 48))

    await validate_term_fields(
        months=payload.months,
        rate=payload.rate,
        rate_unit=payload.rate_unit,
        min_amount=payload.min_amount,
        max_months=max_months,
        active=payload.active,
    )

    now = datetime.now(timezone.utc)

    # 3. Enforce a unique sort order automatically:
    # When sort collides, shift the others, and by default set new terms' sort = max(sort) + 1.
    if payload.sort is None or payload.sort <= 0:
        cursor = db[SAVINGS_TERMS_COLLECTION].find({}).sort("sort", -1).limit(1)
        highest_sort_terms = await cursor.to_list(1)
        target_sort = (int(highest_sort_terms[0].get("sort", 0)) + 1) if highest_sort_terms else 1
    else:
        target_sort = int(payload.sort)
        collision = await db[SAVINGS_TERMS_COLLECTION].find_one({"sort": target_sort})
        if collision:
            await db[SAVINGS_TERMS_COLLECTION].update_many(
                {"sort": {"$gte": target_sort}},
                {"$inc": {"sort": 1}},
            )

    term_doc = {
        "label": payload.label.strip(),
        "months": payload.months,
        "rate": float(payload.rate),
        "rate_unit": payload.rate_unit,
        "min_amount": float(payload.min_amount) if payload.min_amount is not None else None,
        "active": payload.active,
        "sort": target_sort,
        "created_at": now,
        "updated_at": now,
    }

    result = await db[SAVINGS_TERMS_COLLECTION].insert_one(term_doc)
    term_id = str(result.inserted_id)

    # Audit log
    await write_audit_log(
        admin_id=admin_id,
        action="create_term",
        old_value=None,
        new_value={"term_id": term_id, **term_doc, "created_at": str(now), "updated_at": str(now)},
    )

    warnings = await compute_term_warnings()

    return {
        "success": True,
        "message": f"Savings term '{payload.label}' created successfully.",
        "data": {
            "id": term_id,
            **term_doc,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
        },
        "warnings": warnings,
    }


@router.patch("/admin/savings/terms/{id}")
async def admin_update_term(
    id: str,
    payload: SavingsTermUpdate,
    current_admin: dict = Depends(get_current_user),
):
    """
    PATCH /admin/savings/terms/{id}
    Edits an existing term (label, months, rate, rate_unit, min_amount, active, sort).
    Validates fields and active months uniqueness. Writes audit log.
    Existing deposits remain locked and unaffected.
    """
    require_admin(current_admin)
    admin_id = str(current_admin.get("_id", "admin"))

    if not ObjectId.is_valid(id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid term ID",
        )

    old_term = await db[SAVINGS_TERMS_COLLECTION].find_one({"_id": ObjectId(id)})
    if not old_term:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Savings term not found",
        )

    settings = await get_or_create_settings()
    max_months = int(settings.get("max_months", 48))

    # Resolve merged values for validation
    new_months = payload.months if payload.months is not None else int(old_term.get("months", 1))
    new_rate = payload.rate if payload.rate is not None else float(old_term.get("rate", 0.015))
    new_rate_unit = payload.rate_unit if payload.rate_unit is not None else str(old_term.get("rate_unit", "annual"))
    new_min_amount = payload.min_amount if payload.min_amount is not None else old_term.get("min_amount")
    new_active = payload.active if payload.active is not None else bool(old_term.get("active", True))
    new_label = payload.label.strip() if payload.label is not None else str(old_term.get("label", ""))
    # Resolve unique sort order automatically on collision
    if payload.sort is not None:
        target_sort = int(payload.sort)
        old_sort = int(old_term.get("sort", 0))
        if target_sort != old_sort:
            collision = await db[SAVINGS_TERMS_COLLECTION].find_one(
                {"sort": target_sort, "_id": {"$ne": ObjectId(id)}}
            )
            if collision:
                await db[SAVINGS_TERMS_COLLECTION].update_many(
                    {"sort": {"$gte": target_sort}, "_id": {"$ne": ObjectId(id)}},
                    {"$inc": {"sort": 1}},
                )
        new_sort = target_sort
    else:
        new_sort = int(old_term.get("sort", 0))

    await validate_term_fields(
        months=new_months,
        rate=new_rate,
        rate_unit=new_rate_unit,
        min_amount=new_min_amount,
        max_months=max_months,
        active=new_active,
        exclude_id=id,
    )

    now = datetime.now(timezone.utc)
    update_fields = {
        "label": new_label,
        "months": new_months,
        "rate": float(new_rate),
        "rate_unit": new_rate_unit,
        "min_amount": float(new_min_amount) if new_min_amount is not None else None,
        "active": new_active,
        "sort": new_sort,
        "updated_at": now,
    }

    updated_term = await db[SAVINGS_TERMS_COLLECTION].find_one_and_update(
        {"_id": ObjectId(id)},
        {"$set": update_fields},
        return_document=ReturnDocument.AFTER,
    )

    # Format audit log old & new values
    old_clean = {
        "label": old_term.get("label"),
        "months": old_term.get("months"),
        "rate": old_term.get("rate"),
        "rate_unit": old_term.get("rate_unit"),
        "min_amount": old_term.get("min_amount"),
        "active": old_term.get("active"),
        "sort": old_term.get("sort"),
    }
    new_clean = {
        "label": new_label,
        "months": new_months,
        "rate": float(new_rate),
        "rate_unit": new_rate_unit,
        "min_amount": float(new_min_amount) if new_min_amount is not None else None,
        "active": new_active,
        "sort": new_sort,
    }

    await write_audit_log(
        admin_id=admin_id,
        action="update_term",
        old_value={"term_id": id, **old_clean},
        new_value={"term_id": id, **new_clean},
    )

    warnings = await compute_term_warnings()

    return {
        "success": True,
        "message": f"Savings term '{new_label}' updated successfully.",
        "data": {
            "id": str(updated_term["_id"]),
            "label": updated_term.get("label"),
            "months": updated_term.get("months"),
            "rate": updated_term.get("rate"),
            "rate_unit": updated_term.get("rate_unit"),
            "min_amount": updated_term.get("min_amount"),
            "active": updated_term.get("active"),
            "sort": updated_term.get("sort"),
            "updated_at": now.isoformat(),
        },
        "warnings": warnings,
    }


@router.delete("/admin/savings/terms/{id}")
async def admin_delete_term(
    id: str,
    current_admin: dict = Depends(get_current_user),
):
    """
    DELETE /admin/savings/terms/{id}
    Soft delete only (sets active=false). Never hard delete terms so historical data stays sound.
    Writes audit log.
    """
    require_admin(current_admin)
    admin_id = str(current_admin.get("_id", "admin"))

    if not ObjectId.is_valid(id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid term ID",
        )

    old_term = await db[SAVINGS_TERMS_COLLECTION].find_one({"_id": ObjectId(id)})
    if not old_term:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Savings term not found",
        )

    now = datetime.now(timezone.utc)
    updated_term = await db[SAVINGS_TERMS_COLLECTION].find_one_and_update(
        {"_id": ObjectId(id)},
        {"$set": {"active": False, "updated_at": now}},
        return_document=ReturnDocument.AFTER,
    )

    await write_audit_log(
        admin_id=admin_id,
        action="delete_term",
        old_value={"term_id": id, "active": old_term.get("active")},
        new_value={"term_id": id, "active": False},
    )

    warnings = await compute_term_warnings()

    return {
        "success": True,
        "message": f"Term '{old_term.get('label')}' deactivated successfully (soft-deleted).",
        "data": {
            "id": str(updated_term["_id"]),
            "active": False,
        },
        "warnings": warnings,
    }


@router.put("/admin/savings/settings")
async def admin_update_global_settings(
    payload: SavingsGlobalSettingsUpdate,
    current_admin: dict = Depends(get_current_user),
):
    """
    PUT /admin/savings/settings
    Updates global savings settings: min_deposit and max_months.
    Writes audit log.
    """
    require_admin(current_admin)
    admin_id = str(current_admin.get("_id", "admin"))

    if payload.min_deposit <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Minimum deposit must be greater than $0.00.",
        )
    if payload.max_months < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Max months must be at least 1.",
        )

    old_settings = await get_or_create_settings()
    now = datetime.now(timezone.utc)

    updated_settings = await db[SAVINGS_SETTINGS_COLLECTION].find_one_and_update(
        {"_id": "savings"},
        {
            "$set": {
                "min_deposit": float(payload.min_deposit),
                "max_months": int(payload.max_months),
                "updated_at": now,
                "updated_by": str(current_admin.get("phone_number", admin_id)),
            }
        },
        upsert=True,
        return_document=ReturnDocument.AFTER,
    )

    await write_audit_log(
        admin_id=admin_id,
        action="update_settings",
        old_value={
            "min_deposit": old_settings.get("min_deposit"),
            "max_months": old_settings.get("max_months"),
        },
        new_value={
            "min_deposit": payload.min_deposit,
            "max_months": payload.max_months,
        },
    )

    warnings = await compute_term_warnings()

    return {
        "success": True,
        "message": "Global savings settings updated successfully.",
        "data": {
            "min_deposit": float(updated_settings.get("min_deposit", payload.min_deposit)),
            "max_months": int(updated_settings.get("max_months", payload.max_months)),
            "updated_at": now.isoformat(),
        },
        "warnings": warnings,
    }


@router.get("/admin/savings/settings")
async def admin_get_global_settings(
    current_admin: dict = Depends(get_current_user),
):
    """Admin retrieves global savings settings."""
    require_admin(current_admin)
    settings = await get_or_create_settings()
    return {
        "success": True,
        "data": {
            "min_deposit": float(settings.get("min_deposit", 5.0)),
            "max_months": int(settings.get("max_months", 48)),
            "updated_at": settings.get("updated_at"),
            "updated_by": settings.get("updated_by", "admin"),
        },
    }


# =========================================================
# CUSTOMER ENDPOINTS
# =========================================================

@router.get("/savings/terms")
async def get_customer_savings_terms():
    """
    GET /savings/terms
    Returns only active terms, sorted by sort asc, months asc.
    Each with: id, label, months, rate, rate_unit, annual_equivalent,
    monthly_equivalent, min_amount.
    """
    await ensure_seeded_terms()
    settings = await get_or_create_settings()
    global_min = float(settings.get("min_deposit", 5.0))

    cursor = db[SAVINGS_TERMS_COLLECTION].find({"active": True}).sort([("sort", 1), ("months", 1)])
    terms_list = await cursor.to_list(100)

    result = []
    for t in terms_list:
        rate = float(t.get("rate", 0.0))
        unit = t.get("rate_unit", "annual")
        annual_eq = rate if unit == "annual" else round(rate * 12, 6)
        monthly_eq = round(rate / 12, 6) if unit == "annual" else rate
        min_amt = float(t.get("min_amount")) if t.get("min_amount") is not None else global_min

        result.append({
            "id": str(t["_id"]),
            "label": t.get("label", ""),
            "months": int(t.get("months", 1)),
            "rate": rate,
            "rate_unit": unit,
            "annual_equivalent": annual_eq,
            "monthly_equivalent": monthly_eq,
            "min_amount": min_amt,
        })

    return {
        "success": True,
        "data": result,
    }


# Backwards compatibility alias for older mobile app builds
@router.get("/savings/settings")
async def get_savings_settings_legacy():
    """Legacy endpoint returning savings terms and rates for older mobile builds."""
    await ensure_seeded_terms()
    settings = await get_or_create_settings()
    terms_res = await get_customer_savings_terms()
    return {
        "success": True,
        "data": {
            "min_deposit": float(settings.get("min_deposit", 5.0)),
            "currency": "USD",
            "terms": terms_res.get("data", []),
        },
    }


@router.post("/savings/open")
async def open_savings_deposit(
    payload: SavingsOpenRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    POST /savings/open
    Takes {term_id, amount} only.
    Server loads the term, ignores any rate/interest sent by client,
    checks term is active, amount >= min, amount <= balance,
    debits balance atomically, checks System Wallet reserve, and creates deposit.
    Locks on deposit at open time:
      term_id, label, months, rate, rate_unit, interest_amount, maturity_date.
    Later admin edits must NOT affect existing deposits.
    """
    require_customer(current_user)
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    # 1. Fetch term
    if not ObjectId.is_valid(payload.term_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid term ID provided",
        )

    term = await db[SAVINGS_TERMS_COLLECTION].find_one({"_id": ObjectId(payload.term_id)})
    if not term:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Selected savings term was not found",
        )
    if not term.get("active", True):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The selected savings term is currently inactive and not accepting new deposits.",
        )

    term_months = int(term.get("months", 1))
    term_rate = float(term.get("rate", 0.015))
    term_rate_unit = str(term.get("rate_unit", "annual"))
    term_label = str(term.get("label", f"{term_months} Months"))

    # 2. Check min deposit requirement
    settings = await get_or_create_settings()
    global_min = float(settings.get("min_deposit", 5.0))
    required_min = float(term.get("min_amount")) if term.get("min_amount") is not None else global_min

    if payload.amount < required_min:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Minimum deposit for '{term_label}' is ${required_min:.2f}.",
        )

    # 3. Check customer account and balance
    account = await db["accounts"].find_one({"user_id": user_id})
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer account not found",
        )
    if account.get("is_frozen", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is frozen. Cannot deposit into savings.",
        )

    user_balance = float(account.get("balance", 0.0))
    if payload.amount > user_balance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient balance",
        )

    # 4. Server-side Interest & Maturity calculation
    interest_amount, total_payout = calculate_interest(
        principal=payload.amount,
        rate=term_rate,
        months=term_months,
        rate_unit=term_rate_unit,
    )
    maturity_date = calculate_maturity_date(start_date=now, months=term_months)

    # 5. System Wallet reserve check:
    # Reject if System Wallet cannot cover total projected interest of all active deposits plus this one.
    pipeline = [
        {"$match": {"status": "active"}},
        {
            "$group": {
                "_id": None,
                "total_active_interest": {
                    "$sum": {"$ifNull": ["$interest_amount", "$expected_interest"]}
                },
            }
        },
    ]
    cursor = db[SAVINGS_COLLECTION].aggregate(pipeline)
    agg_res = await cursor.to_list(length=1)
    current_active_interest = (
        Decimal(str(agg_res[0]["total_active_interest"])) if agg_res else Decimal("0.00")
    )
    new_interest_dec = Decimal(str(interest_amount))
    total_required_interest = current_active_interest + new_interest_dec

    system_wallet = await db["system_wallets"].find_one({"wallet_key": "main"})
    sys_bal = (
        Decimal(str(system_wallet.get("balance", 0.0)))
        if system_wallet
        else Decimal("0.00")
    )

    if sys_bal < total_required_interest:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"System Wallet has insufficient funds to cover projected interest payout. "
                f"Required reserve: ${float(total_required_interest):.2f}, Available: ${float(sys_bal):.2f}"
            ),
        )

    # 6. Debit user balance atomically ($gte and $inc)
    update_res = await db["accounts"].update_one(
        {
            "user_id": user_id,
            "is_frozen": {"$ne": True},
            "balance": {"$gte": float(payload.amount)},
        },
        {
            "$inc": {"balance": -float(payload.amount)},
            "$set": {"updated_at": now},
        },
    )

    if update_res.modified_count == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient balance",
        )

    # 7. Lock rate, term, and maturity date on the deposit document
    saving_id = generate_saving_id()
    user_name = f"{current_user.get('first_name', '')} {current_user.get('last_name', '')}".strip()
    phone = current_user.get("phone_number", "")

    saving_doc = {
        "saving_id": saving_id,
        "user_id": user_id,
        "user_name": user_name,
        "phone_number": phone,
        "account_id": str(account["_id"]),
        "account_number": account.get("account_number", ""),
        # Core term lock fields
        "term_id": str(term["_id"]),
        "label": term_label,
        "term": term_label,  # backwards compatibility
        "months": term_months,
        "duration_months": term_months,  # backwards compatibility
        "rate": term_rate,
        "interest_rate": term_rate,  # backwards compatibility
        "rate_unit": term_rate_unit,
        "duration_type": term_rate_unit,  # backwards compatibility
        "principal": float(payload.amount),
        "principal_amount": float(payload.amount),  # backwards compatibility
        "interest_amount": interest_amount,
        "expected_interest": interest_amount,  # backwards compatibility
        "total_payout": total_payout,
        "start_date": now,
        "maturity_date": maturity_date,
        "status": "active",
        "notes": payload.notes or "",
        "created_at": now,
        "updated_at": now,
    }

    result = await db[SAVINGS_COLLECTION].insert_one(saving_doc)

    # 8. Record 'savings_open' transaction
    trans_id = f"SAV-OPN-{uuid4().hex[:10].upper()}"
    balance_before = user_balance
    balance_after = user_balance - float(payload.amount)

    unit_display = "% p.a." if term_rate_unit == "annual" else "% /mo"
    rate_display = f"{term_rate * 100:.2f}{unit_display}"

    await db["transactions"].insert_one({
        "transaction_id": trans_id,
        "user_id": user_id,
        "account_id": str(account["_id"]),
        "type": "savings_open",
        "amount": float(payload.amount),
        "balance_before": balance_before,
        "balance_after": balance_after,
        "currency": "USD",
        "status": "SUCCESS",
        "description": f"Savings Deposit Opened ({term_label} @ {rate_display})",
        "saving_id": saving_id,
        "created_at": now,
    })

    return {
        "success": True,
        "message": f"Successfully deposited ${payload.amount:.2f} into savings ({term_label} @ {rate_display}). Funds locked until maturity.",
        "data": {
            "id": str(result.inserted_id),
            "saving_id": saving_id,
            "term_id": str(term["_id"]),
            "label": term_label,
            "principal": float(payload.amount),
            "rate": term_rate,
            "rate_unit": term_rate_unit,
            "months": term_months,
            "interest_amount": interest_amount,
            "total_payout": total_payout,
            "start_date": now.isoformat(),
            "maturity_date": maturity_date.isoformat(),
            "status": "active",
            "new_balance": balance_after,
        },
    }


# Backwards compatibility handler for /savings/deposit
@router.post("/savings/deposit")
async def create_savings_deposit_compat(
    payload: SavingsDepositCreate,
    current_user: dict = Depends(get_current_user),
):
    """
    Backwards compatibility endpoint for older clients calling /savings/deposit.
    Resolves matching term_id and forwards to open_savings_deposit.
    """
    term_id = payload.term_id
    if not term_id:
        # Match by duration_months or fallback to first active term
        target_months = payload.duration_months or 12
        term = await db[SAVINGS_TERMS_COLLECTION].find_one({"months": target_months, "active": True})
        if not term:
            term = await db[SAVINGS_TERMS_COLLECTION].find_one({"active": True})
        if not term:
            await ensure_seeded_terms()
            term = await db[SAVINGS_TERMS_COLLECTION].find_one({"active": True})
        term_id = str(term["_id"])

    open_req = SavingsOpenRequest(
        term_id=term_id,
        amount=payload.amount,
        notes=payload.notes,
    )
    return await open_savings_deposit(payload=open_req, current_user=current_user)


# Export alias for backwards compatibility
create_savings_deposit = create_savings_deposit_compat
admin_update_savings_settings = admin_update_global_settings


@router.get("/savings/my-savings")
async def get_my_savings(
    current_user: dict = Depends(get_current_user),
):
    """Retrieve logged in customer's savings accounts and status."""
    require_customer(current_user)
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    cursor = db[SAVINGS_COLLECTION].find({"user_id": user_id}).sort("created_at", -1)
    savings_list = await cursor.to_list(length=200)

    total_savings = 0.0
    total_earned_interest = 0.0
    active_savings = []
    completed_savings = []

    for item in savings_list:
        maturity_date = item.get("maturity_date")
        if isinstance(maturity_date, datetime) and maturity_date.tzinfo is None:
            maturity_date = maturity_date.replace(tzinfo=timezone.utc)

        is_matured = maturity_date <= now if maturity_date else False
        status_val = item.get("status", "active")

        # Calculate days remaining
        days_remaining = 0
        if maturity_date and maturity_date > now:
            days_remaining = (maturity_date - now).days + 1

        principal = float(item.get("principal") or item.get("principal_amount", 0.0))
        interest = float(item.get("interest_amount") or item.get("expected_interest", 0.0))
        rate = float(item.get("rate") or item.get("interest_rate", 0.0))
        term_str = item.get("label") or item.get("term") or f"{item.get('duration_months', 1)} mo"
        rate_unit = item.get("rate_unit", "annual")
        total_payout = float(item.get("total_payout", principal + interest))

        saving_data = {
            "id": str(item["_id"]),
            "saving_id": item.get("saving_id", ""),
            "term_id": item.get("term_id", ""),
            "label": term_str,
            "term": term_str,
            "principal": principal,
            "principal_amount": principal,
            "months": item.get("months", item.get("duration_months", 1)),
            "duration_months": item.get("duration_months", 1),
            "rate": rate,
            "interest_rate": rate,
            "rate_unit": rate_unit,
            "duration_type": item.get("duration_type", rate_unit),
            "interest_amount": interest,
            "expected_interest": interest,
            "total_payout": total_payout,
            "start_date": item.get("start_date").isoformat() if item.get("start_date") else None,
            "maturity_date": maturity_date.isoformat() if maturity_date else None,
            "days_remaining": days_remaining,
            "is_matured": is_matured,
            "can_withdraw": is_matured and status_val == "active",
            "status": status_val,
            "notes": item.get("notes", ""),
            "created_at": item.get("created_at").isoformat() if item.get("created_at") else None,
        }

        if status_val == "active":
            total_savings += principal
            total_earned_interest += interest
            active_savings.append(saving_data)
        else:
            completed_savings.append(saving_data)

    return {
        "success": True,
        "data": {
            "total_savings": round(total_savings, 2),
            "total_earned_interest": round(total_earned_interest, 2),
            "active_count": len(active_savings),
            "completed_count": len(completed_savings),
            "active_savings": active_savings,
            "completed_savings": completed_savings,
        },
    }


# =========================================================
# SYSTEM WALLET & SAVINGS PAYOUT CORE ENGINE
# =========================================================

async def payout_saving_deposit(saving_id_or_obj: str) -> dict:
    """
    Executes the maturity payout for a savings deposit:
    1. Uses status guard: find_one_and_update with {"status": "active"} -> {"status": "matured"}.
       Guarantees that a deposit can NEVER be paid twice!
    2. Debits interest_amount from System Wallet ("system_wallets", key="main").
    3. Credits (principal + interest) to user's account ("accounts").
    4. Records movements in 'transactions' collection so the books balance:
       - 'savings_payout': user account gets principal + interest
       - 'system_interest_payout': system wallet pays interest
    Works for both new and legacy deposits!
    """
    now = datetime.now(timezone.utc)

    query = {"status": "active"}
    if ObjectId.is_valid(saving_id_or_obj):
        query["_id"] = ObjectId(saving_id_or_obj)
    else:
        query["saving_id"] = str(saving_id_or_obj)

    # Atomic status guard: active -> matured
    saving = await db[SAVINGS_COLLECTION].find_one_and_update(
        query,
        {
            "$set": {
                "status": "matured",
                "matured_at": now,
                "payout_date": now,
                "updated_at": now,
            }
        },
        return_document=ReturnDocument.BEFORE,
    )

    if not saving:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Savings deposit not found or has already matured/been paid out.",
        )

    principal = float(saving.get("principal") or saving.get("principal_amount", 0.0))
    interest = float(saving.get("interest_amount") or saving.get("expected_interest", 0.0))
    total_payout = round(principal + interest, 2)
    user_id = str(saving["user_id"])
    sid = saving.get("saving_id", str(saving.get("_id")))

    # 1. Debit interest part from System Wallet
    sys_wallet = await db["system_wallets"].find_one_and_update(
        {"wallet_key": "main"},
        {
            "$inc": {"balance": -interest},
            "$set": {"updated_at": now},
        },
        return_document=ReturnDocument.AFTER,
    )
    sys_bal_after = float(sys_wallet.get("balance", 0.0)) if sys_wallet else 0.0
    sys_bal_before = sys_bal_after + interest

    # 2. Credit principal + interest to user account
    user_account = await db["accounts"].find_one_and_update(
        {"user_id": user_id},
        {
            "$inc": {"balance": total_payout},
            "$set": {"updated_at": now},
        },
        return_document=ReturnDocument.AFTER,
    )
    if not user_account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer account not found during payout",
        )
    user_bal_after = float(user_account.get("balance", 0.0))
    user_bal_before = user_bal_after - total_payout

    # 3. Record 'savings_payout' transaction for user
    trans_payout_id = f"SAV-PAY-{uuid4().hex[:10].upper()}"
    await db["transactions"].insert_one({
        "transaction_id": trans_payout_id,
        "user_id": user_id,
        "account_id": str(user_account["_id"]),
        "type": "savings_payout",
        "amount": total_payout,
        "principal": principal,
        "interest": interest,
        "balance_before": user_bal_before,
        "balance_after": user_bal_after,
        "currency": "USD",
        "status": "SUCCESS",
        "description": f"Savings Maturity Payout (Principal: ${principal:.2f} + Interest: ${interest:.2f})",
        "saving_id": sid,
        "created_at": now,
    })

    # 4. Record 'system_interest_payout' transaction for System Wallet
    trans_sys_id = f"SYS-INT-{uuid4().hex[:10].upper()}"
    await db["transactions"].insert_one({
        "transaction_id": trans_sys_id,
        "user_id": "system",
        "account_id": "system_wallet_main",
        "type": "system_interest_payout",
        "amount": interest,
        "balance_before": sys_bal_before,
        "balance_after": sys_bal_after,
        "currency": "USD",
        "status": "SUCCESS",
        "description": f"System Interest Payout for Savings ({sid})",
        "saving_id": sid,
        "created_at": now,
    })

    return {
        "success": True,
        "message": f"Successfully paid out ${total_payout:.2f} (Principal: ${principal:.2f} + Interest: ${interest:.2f}) to customer.",
        "data": {
            "saving_id": sid,
            "principal": principal,
            "interest": interest,
            "total_payout": total_payout,
            "user_balance_after": user_bal_after,
            "system_balance_after": sys_bal_after,
            "status": "matured",
        },
    }


# =========================================================
# WITHDRAW SAVINGS (AFTER MATURITY)
# =========================================================

@router.post("/savings/{saving_id}/withdraw")
async def withdraw_savings(
    saving_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Withdraw savings deposit after maturity.
    ENFORCES: User CANNOT withdraw money if they are currently saving money (before maturity).
    """
    require_customer(current_user)
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    saving = await db[SAVINGS_COLLECTION].find_one({
        "saving_id": saving_id,
        "user_id": user_id,
    })

    if not saving:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Savings deposit not found",
        )

    if saving.get("status") in ("matured", "completed"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This savings deposit has already been paid out and completed.",
        )

    maturity_date = saving.get("maturity_date")
    if isinstance(maturity_date, datetime) and maturity_date.tzinfo is None:
        maturity_date = maturity_date.replace(tzinfo=timezone.utc)

    if maturity_date and now < maturity_date:
        remaining_days = (maturity_date - now).days + 1
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Cannot withdraw money while currently saving! "
                f"This savings deposit is locked until {maturity_date.strftime('%b %d, %Y')} "
                f"({remaining_days} days remaining) to earn interest."
            ),
        )

    return await payout_saving_deposit(str(saving["_id"]))


# =========================================================
# DEV-ONLY: SIMULATE MATURITY PAYOUT
# =========================================================

@router.post("/admin/savings/{id}/simulate-maturity")
async def simulate_savings_maturity(
    id: str,
    current_admin: dict = Depends(get_current_user),
):
    """
    Dev-only endpoint (admin auth required, enabled in dev/debug mode).
    Simulates immediate maturity payout for end-to-end testing.
    """
    require_admin(current_admin)

    from app.config import settings
    is_dev = getattr(settings, "DEBUG", False) or getattr(settings, "ENVIRONMENT", "").lower() in (
        "development",
        "dev",
        "test",
    )
    if not is_dev:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Simulate maturity endpoint is disabled in production.",
        )

    query = {}
    if ObjectId.is_valid(id):
        query = {"$or": [{"_id": ObjectId(id)}, {"saving_id": id}]}
    else:
        query = {"saving_id": id}

    saving = await db[SAVINGS_COLLECTION].find_one(query)
    if not saving:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Savings deposit not found",
        )

    if saving.get("status") in ("matured", "completed"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This savings deposit has already been paid out and matured.",
        )

    result = await payout_saving_deposit(str(saving["_id"]))
    return {
        "success": True,
        "message": f"Successfully simulated maturity payout for deposit {saving.get('saving_id')}",
        "data": result.get("data", result),
    }


# =========================================================
# ADMIN SAVINGS OVERVIEW (FOR ADMIN DASHBOARD & SAVINGS PAGE)
# =========================================================

@router.get("/admin/savings/overview")
async def admin_savings_overview(
    current_admin: dict = Depends(get_current_user),
):
    """Admin view of all customer savings deposits and aggregate stats."""
    require_admin(current_admin)
    now = datetime.now(timezone.utc)
    await ensure_seeded_terms()

    cursor = db[SAVINGS_COLLECTION].find({}).sort("created_at", -1)
    all_savings = await cursor.to_list(length=500)

    total_active_volume = 0.0
    total_projected_interest = 0.0
    total_completed_payout = 0.0
    active_count = 0
    completed_count = 0
    unique_active_users = set()

    formatted_list = []
    for item in all_savings:
        status_val = item.get("status", "active")
        principal = float(item.get("principal") or item.get("principal_amount", 0.0))
        interest = float(item.get("interest_amount") or item.get("expected_interest", 0.0))
        rate = float(item.get("rate") or item.get("interest_rate", 0.0))
        term_label = item.get("label") or item.get("term") or f"{item.get('duration_months', 1)} mo"
        payout = float(item.get("total_payout", principal + interest))
        uid = str(item.get("user_id", ""))

        maturity_date = item.get("maturity_date")
        if isinstance(maturity_date, datetime) and maturity_date.tzinfo is None:
            maturity_date = maturity_date.replace(tzinfo=timezone.utc)

        is_matured = maturity_date <= now if maturity_date else False

        if status_val == "active":
            active_count += 1
            total_active_volume += principal
            total_projected_interest += interest
            if uid:
                unique_active_users.add(uid)
        else:
            completed_count += 1
            total_completed_payout += payout

        formatted_list.append({
            "id": str(item["_id"]),
            "saving_id": item.get("saving_id", ""),
            "term_id": item.get("term_id", ""),
            "user_id": uid,
            "user_name": item.get("user_name", "Unknown"),
            "phone_number": item.get("phone_number", ""),
            "principal": principal,
            "principal_amount": principal,
            "term": term_label,
            "label": term_label,
            "months": item.get("months", item.get("duration_months", 1)),
            "rate": rate,
            "interest_rate": rate,
            "rate_unit": item.get("rate_unit", "annual"),
            "interest_amount": interest,
            "expected_interest": interest,
            "total_payout": payout,
            "start_date": item.get("start_date").isoformat() if item.get("start_date") else None,
            "maturity_date": maturity_date.isoformat() if maturity_date else None,
            "is_matured": is_matured,
            "status": status_val,
            "created_at": item.get("created_at").isoformat() if item.get("created_at") else None,
        })

    settings = await get_or_create_settings()
    terms_cursor = db[SAVINGS_TERMS_COLLECTION].find({"active": True}).sort([("sort", 1), ("months", 1)])
    active_terms = await terms_cursor.to_list(100)
    warnings = await compute_term_warnings()

    return {
        "success": True,
        "data": {
            "settings": {
                "min_deposit": float(settings.get("min_deposit", 5.0)),
                "max_months": int(settings.get("max_months", 48)),
            },
            "stats": {
                "total_active_volume": round(total_active_volume, 2),
                "total_projected_interest": round(total_projected_interest, 2),
                "total_completed_payout": round(total_completed_payout, 2),
                "active_savings_count": active_count,
                "completed_savings_count": completed_count,
                "unique_savers_count": len(unique_active_users),
            },
            "savings": formatted_list,
            "active_terms_count": len(active_terms),
            "warnings": warnings,
        },
    }
