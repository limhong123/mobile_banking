import secrets
from datetime import (
    datetime,
    timezone,
)

from fastapi import HTTPException

from app.database import db


AGENT_WALLET_COLLECTION = (
    "agent_wallets"
)

CUSTOMER_ACCOUNT_COLLECTION = (
    "accounts"
)

CASH_TRANSFER_COLLECTION = (
    "cash_transfers"
)


# =========================================================
# PHONE NORMALIZATION
# =========================================================

def normalize_phone(
    phone: str,
) -> str:
    value = (
        phone
        .strip()
        .replace(" ", "")
        .replace("-", "")
        .replace("(", "")
        .replace(")", "")
    )

    if value.startswith("+"):
        digits = (
            "+"
            + "".join(
                c
                for c in value[1:]
                if c.isdigit()
            )
        )
    else:
        digits_only = "".join(
            c
            for c in value
            if c.isdigit()
        )

        # Cambodia local phone:
        # 098494201 -> +85598494201
        if digits_only.startswith(
            "0"
        ):
            digits = (
                "+855"
                + digits_only[1:]
            )

        # 85598494201 -> +85598494201
        elif digits_only.startswith(
            "855"
        ):
            digits = (
                "+"
                + digits_only
            )

        else:
            digits = (
                "+"
                + digits_only
            )

    if len(digits) < 9:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid phone number"
            ),
        )

    return digits


# =========================================================
# GENERATE UNIQUE NUMERIC CODE
# =========================================================

async def generate_unique_code():
    while True:
        code = "".join(
            str(
                secrets.randbelow(
                    10
                )
            )
            for _ in range(12)
        )

        existing = await db[
            CASH_TRANSFER_COLLECTION
        ].find_one(
            {
                "code":
                    code,
            },
            {
                "_id":
                    1,
            },
        )

        if not existing:
            return code


# =========================================================
# TRANSFER ID
# =========================================================

def generate_transfer_id():
    return (
        "CASH-"
        + secrets
        .token_hex(6)
        .upper()
    )


# =========================================================
# CURRENT TIME
# =========================================================

def utc_now():
    return datetime.now(
        timezone.utc
    )


# =========================================================
# FIND USER BY PHONE
# =========================================================

async def find_user_by_phone(
    phone: str,
):
    normalized = normalize_phone(
        phone
    )

    user = await db[
        "users"
    ].find_one(
        {
            "phone_number":
                normalized,
        }
    )

    return user


# =========================================================
# DISPLAY NAME
# =========================================================

def full_name(
    user: dict | None,
):
    if not user:
        return ""

    return (
        f"{user.get('first_name', '')} "
        f"{user.get('last_name', '')}"
    ).strip()