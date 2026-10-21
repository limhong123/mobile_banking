from datetime import (
    datetime,
    timezone,
)
from uuid import uuid4

from app.database import db


# =========================================================
# GENERATE ACCOUNT NUMBER
# =========================================================

async def generate_account_number():
    while True:
        account_number = (
            str(
                uuid4().int
            )[:14]
        )

        exists = await db[
            "accounts"
        ].find_one(
            {
                "account_number":
                    account_number,
            }
        )

        if not exists:
            return account_number


# =========================================================
# GENERATE QR ID
# =========================================================

async def generate_qr_id():
    while True:
        qr_id = (
            "KHP-"
            + uuid4()
            .hex[:10]
            .upper()
        )

        exists = await db[
            "accounts"
        ].find_one(
            {
                "qr_id":
                    qr_id,
            }
        )

        if not exists:
            return qr_id


# =========================================================
# ENSURE ACCOUNT
# =========================================================

async def ensure_customer_account(
    user_id: str,
):
    account = await db[
        "accounts"
    ].find_one(
        {
            "user_id":
                user_id,
        }
    )

    now = datetime.now(
        timezone.utc
    )

    # =====================================================
    # EXISTING ACCOUNT
    # =====================================================

    if account:
        updates = {}

        if not account.get(
            "account_number"
        ):
            updates[
                "account_number"
            ] = (
                await generate_account_number()
            )

        if not account.get(
            "qr_id"
        ):
            qr_id = (
                await generate_qr_id()
            )

            updates[
                "qr_id"
            ] = qr_id

            updates[
                "qr_payload"
            ] = (
                f"KHPAY:PAY:{qr_id}"
            )

            updates[
                "qr_active"
            ] = True

        if (
            "is_frozen"
            not in account
        ):
            updates[
                "is_frozen"
            ] = False

        if updates:
            updates[
                "updated_at"
            ] = now

            await db[
                "accounts"
            ].update_one(
                {
                    "_id":
                        account[
                            "_id"
                        ],
                },
                {
                    "$set":
                        updates,
                },
            )

            account = await db[
                "accounts"
            ].find_one(
                {
                    "_id":
                        account[
                            "_id"
                        ],
                }
            )

        return account

    # =====================================================
    # NEW ACCOUNT
    # =====================================================

    account_number = (
        await generate_account_number()
    )

    qr_id = (
        await generate_qr_id()
    )

    document = {
        "user_id":
            user_id,

        "account_number":
            account_number,

        "balance":
            0.0,

        "currency":
            "USD",

        "qr_id":
            qr_id,

        "qr_payload":
            f"KHPAY:PAY:{qr_id}",

        "qr_active":
            True,

        "is_frozen":
            False,

        "created_at":
            now,

        "updated_at":
            now,
    }

    result = await db[
        "accounts"
    ].insert_one(
        document
    )

    return await db[
        "accounts"
    ].find_one(
        {
            "_id":
                result.inserted_id,
        }
    )