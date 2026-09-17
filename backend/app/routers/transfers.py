import asyncio

from datetime import (
    datetime,
    timezone,
)

from decimal import Decimal

from uuid import uuid4

from bson import ObjectId

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)

from pymongo import (
    ReturnDocument,
)

from app.database import db

from app.dependencies import (
    get_current_user,
)

from app.schemas.transfer_schema import (
    ResolveAccountRequest,
    ResolveQrRequest,
    TransferCreate,
)

from app.services.account_service import (
    ensure_customer_account,
)

from app.services.firebase_notification_service import (
    send_notification,
)


router = APIRouter(
    prefix="/transfers",
    tags=["Transfers"],
)


# =========================================================
# TRANSACTION ID
# =========================================================

def generate_transfer_id():
    return (
        "TRF-"
        + uuid4()
        .hex[:12]
        .upper()
    )


# =========================================================
# REQUIRE CUSTOMER
# =========================================================

def require_customer(
    user: dict,
):
    if (
        user.get(
            "role",
            "user",
        )
        != "user"
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "Customer account required"
            ),
        )

    if not user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "Account disabled"
            ),
        )

    if user.get(
        "kyc_status"
    ) != "approved":
        raise HTTPException(
            status_code=403,
            detail=(
                "KYC not approved"
            ),
        )


# =========================================================
# GET RECEIVER USER
# =========================================================

async def get_receiver_user(
    receiver_account: dict,
):
    try:
        receiver_id = ObjectId(
            receiver_account[
                "user_id"
            ]
        )

    except Exception:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid receiver account"
            ),
        )

    receiver = await db[
        "users"
    ].find_one(
        {
            "_id":
                receiver_id,
        }
    )

    if not receiver:
        raise HTTPException(
            status_code=404,
            detail=(
                "Receiver not found"
            ),
        )

    return receiver


# =========================================================
# VALIDATE RECEIVER
# =========================================================

def validate_receiver(
    sender: dict,
    receiver: dict,
    receiver_account: dict,
):
    if (
        str(
            sender["_id"]
        )
        ==
        str(
            receiver["_id"]
        )
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "You cannot transfer money to yourself"
            ),
        )

    if not receiver.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Receiver account is disabled"
            ),
        )

    if receiver.get(
        "kyc_status"
    ) != "approved":
        raise HTTPException(
            status_code=400,
            detail=(
                "Receiver KYC is not approved"
            ),
        )

    if receiver_account.get(
        "is_frozen",
        False,
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "Receiver wallet is frozen"
            ),
        )


# =========================================================
# RESPONSE RECEIVER
# =========================================================

def receiver_response(
    receiver: dict,
    account: dict,
):
    name = (
        f"{receiver.get('first_name', '')} "
        f"{receiver.get('last_name', '')}"
    ).strip()

    return {
        "success":
            True,

        "data": {
            "receiver_name":
                name,

            "receiver_account_number":
                account.get(
                    "account_number",
                    "",
                ),

            "receiver_qr_id":
                account.get(
                    "qr_id",
                    "",
                ),

            "currency":
                account.get(
                    "currency",
                    "USD",
                ),
        },
    }


# =========================================================
# RESOLVE ACCOUNT NUMBER
# =========================================================

@router.post(
    "/resolve-account"
)
async def resolve_account(
    payload: ResolveAccountRequest,

    current_user: dict = Depends(
        get_current_user
    ),
):
    require_customer(
        current_user
    )

    account_number = (
        payload.account_number
        .strip()
        .upper()
    )

    receiver_account = await db[
        "accounts"
    ].find_one(
        {
            "account_number":
                account_number,
        }
    )

    if not receiver_account:
        raise HTTPException(
            status_code=404,
            detail=(
                "Account number not found"
            ),
        )

    receiver = await get_receiver_user(
        receiver_account
    )

    validate_receiver(
        current_user,
        receiver,
        receiver_account,
    )

    return receiver_response(
        receiver,
        receiver_account,
    )


# =========================================================
# RESOLVE QR
# =========================================================

@router.post(
    "/resolve-qr"
)
async def resolve_qr(
    payload: ResolveQrRequest,

    current_user: dict = Depends(
        get_current_user
    ),
):
    require_customer(
        current_user
    )

    # =====================================================
    # QR VALUE
    # =====================================================

    value = (
        payload.qr_payload
        .strip()
    )

    prefix = "KHPAY:PAY:"

    # =====================================================
    # VALIDATE QR
    # =====================================================

    if not value.startswith(
        prefix
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid KhmerPay QR",
        )

    # Remove:
    # KHPAY:PAY:
    #
    # Example result:
    # ABC123
    #
    # or:
    #
    # ABC123:25.00

    raw_value = (
        value[
            len(prefix):
        ]
        .strip()
    )

    if not raw_value:
        raise HTTPException(
            status_code=400,
            detail="Invalid QR payload",
        )

    # =====================================================
    # SPLIT QR ID AND AMOUNT
    # =====================================================

    parts = raw_value.split(":")

    qr_id = (
        parts[0]
        .strip()
    )

    if not qr_id:
        raise HTTPException(
            status_code=400,
            detail="QR ID is required",
        )

    amount = None

    # =====================================================
    # OPTIONAL AMOUNT
    # =====================================================

    if len(parts) >= 2:
        amount_text = (
            parts[1]
            .strip()
        )

        if amount_text:
            try:
                amount = float(
                    amount_text
                )

            except (
                ValueError,
                TypeError,
            ):
                raise HTTPException(
                    status_code=400,
                    detail="Invalid QR amount",
                )

            if amount <= 0:
                raise HTTPException(
                    status_code=400,
                    detail="QR amount must be greater than 0",
                )

            amount = round(
                amount,
                2,
            )

    # =====================================================
    # FIND RECEIVER ACCOUNT
    # =====================================================

    receiver_account = await db[
        "accounts"
    ].find_one(
        {
            "qr_id":
                qr_id,

            "qr_active":
                True,
        }
    )

    if not receiver_account:
        raise HTTPException(
            status_code=404,
            detail="QR account not found",
        )

    # =====================================================
    # GET RECEIVER USER
    # =====================================================

    receiver = await get_receiver_user(
        receiver_account
    )

    validate_receiver(
        current_user,
        receiver,
        receiver_account,
    )

    # =====================================================
    # RECEIVER NAME
    # =====================================================

    receiver_name = (
        f"{receiver.get('first_name', '')} "
        f"{receiver.get('last_name', '')}"
    ).strip()

    # =====================================================
    # RESPONSE
    # =====================================================

    return {
        "success":
            True,

        "data": {
            "receiver_name":
                receiver_name,

            "receiver_account_number":
                receiver_account.get(
                    "account_number",
                    "",
                ),

            "receiver_qr_id":
                receiver_account.get(
                    "qr_id",
                    "",
                ),

            "currency":
                receiver_account.get(
                    "currency",
                    "USD",
                ),

            "amount":
                amount,
        },
    }

# =========================================================
# TRANSFER
# =========================================================

@router.post("")
async def transfer_money(
    payload: TransferCreate,

    current_user: dict = Depends(
        get_current_user
    ),
):
    require_customer(
        current_user
    )

    sender_id = str(
        current_user[
            "_id"
        ]
    )

    amount = Decimal(
        str(
            payload.amount
        )
    ).quantize(
        Decimal(
            "0.01"
        )
    )

    if amount <= 0:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid amount"
            ),
        )

    # =====================================================
    # SENDER ACCOUNT
    # =====================================================

    sender_account = (
        await ensure_customer_account(
            sender_id
        )
    )

    # =====================================================
    # FIND RECEIVER ACCOUNT
    # =====================================================

    receiver_account = None

    if payload.receiver_account_number:
        receiver_account = await db[
            "accounts"
        ].find_one(
            {
                "account_number":
                    payload
                    .receiver_account_number
                    .strip()
                    .upper(),
            }
        )

    elif payload.receiver_qr_id:
        receiver_account = await db[
            "accounts"
        ].find_one(
            {
                "qr_id":
                    payload
                    .receiver_qr_id
                    .strip(),

                "qr_active":
                    True,
            }
        )

    else:
        raise HTTPException(
            status_code=400,
            detail=(
                "Receiver account or QR required"
            ),
        )

    if not receiver_account:
        raise HTTPException(
            status_code=404,
            detail=(
                "Receiver account not found"
            ),
        )

    # =====================================================
    # RECEIVER USER
    # =====================================================

    receiver = await get_receiver_user(
        receiver_account
    )

    validate_receiver(
        current_user,
        receiver,
        receiver_account,
    )

    now = datetime.now(
        timezone.utc
    )

    # =====================================================
    # DEDUCT SENDER BALANCE
    # =====================================================

    updated_sender = await db[
        "accounts"
    ].find_one_and_update(
        {
            "_id":
                sender_account[
                    "_id"
                ],

            "is_frozen": {
                "$ne":
                    True,
            },

            "balance": {
                "$gte":
                    float(
                        amount
                    ),
            },
        },

        {
            "$inc": {
                "balance":
                    -float(
                        amount
                    ),
            },

            "$set": {
                "updated_at":
                    now,
            },
        },

        return_document=(
            ReturnDocument.AFTER
        ),
    )

    if not updated_sender:
        sender_check = await db[
            "accounts"
        ].find_one(
            {
                "_id":
                    sender_account[
                        "_id"
                    ],
            }
        )

        if (
            sender_check
            and sender_check.get(
                "is_frozen",
                False,
            )
        ):
            raise HTTPException(
                status_code=403,
                detail=(
                    "Your wallet is frozen"
                ),
            )

        raise HTTPException(
            status_code=400,
            detail=(
                "Insufficient balance"
            ),
        )

    sender_after = Decimal(
        str(
            updated_sender.get(
                "balance",
                0,
            )
        )
    )

    sender_before = (
        sender_after
        + amount
    )

    # =====================================================
    # CREDIT RECEIVER
    # =====================================================

    try:
        updated_receiver = await db[
            "accounts"
        ].find_one_and_update(
            {
                "_id":
                    receiver_account[
                        "_id"
                    ],

                "is_frozen": {
                    "$ne":
                        True,
                },
            },

            {
                "$inc": {
                    "balance":
                        float(
                            amount
                        ),
                },

                "$set": {
                    "updated_at":
                        now,
                },
            },

            return_document=(
                ReturnDocument.AFTER
            ),
        )

        if not updated_receiver:
            raise Exception(
                "Receiver wallet unavailable"
            )

    except Exception as error:
        # ================================================
        # ROLLBACK SENDER
        # ================================================

        await db[
            "accounts"
        ].update_one(
            {
                "_id":
                    updated_sender[
                        "_id"
                    ],
            },

            {
                "$inc": {
                    "balance":
                        float(
                            amount
                        ),
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to credit receiver"
            ),
        ) from error

    receiver_after = Decimal(
        str(
            updated_receiver.get(
                "balance",
                0,
            )
        )
    )

    receiver_before = (
        receiver_after
        - amount
    )

    # =====================================================
    # USER NAMES
    # =====================================================

    sender_name = (
        f"{current_user.get('first_name', '')} "
        f"{current_user.get('last_name', '')}"
    ).strip()

    receiver_name = (
        f"{receiver.get('first_name', '')} "
        f"{receiver.get('last_name', '')}"
    ).strip()

    # =====================================================
    # TRANSACTION ID
    # =====================================================

    transaction_id = (
        generate_transfer_id()
    )

    receiver_id = str(
        receiver[
            "_id"
        ]
    )

    # =====================================================
    # TRANSACTION
    # =====================================================

    transaction = {
        "transaction_id":
            transaction_id,

        "type":
            "transfer",

        "sender_id":
            sender_id,

        "sender_name":
            sender_name,

        "sender_account_number":
            sender_account.get(
                "account_number",
                "",
            ),

        "receiver_id":
            receiver_id,

        "receiver_name":
            receiver_name,

        "receiver_account_number":
            receiver_account.get(
                "account_number",
                "",
            ),

        "receiver_qr_id":
            receiver_account.get(
                "qr_id",
                "",
            ),

        "amount":
            float(
                amount
            ),

        "currency":
            "USD",

        "sender_balance_before":
            float(
                sender_before
            ),

        "sender_balance_after":
            float(
                sender_after
            ),

        "receiver_balance_before":
            float(
                receiver_before
            ),

        "receiver_balance_after":
            float(
                receiver_after
            ),

        "status":
            "success",

        "description":
            payload.description
            or "KhmerPay transfer",

        "created_at":
            now,
    }

    # =====================================================
    # SAVE TRANSACTION
    # =====================================================

    try:
        await db[
            "transactions"
        ].insert_one(
            transaction
        )

    except Exception as error:
        # ================================================
        # ROLLBACK SENDER
        # ================================================

        await db[
            "accounts"
        ].update_one(
            {
                "_id":
                    updated_sender[
                        "_id"
                    ],
            },

            {
                "$inc": {
                    "balance":
                        float(
                            amount
                        ),
                },
            },
        )

        # ================================================
        # ROLLBACK RECEIVER
        # ================================================

        await db[
            "accounts"
        ].update_one(
            {
                "_id":
                    updated_receiver[
                        "_id"
                    ],
            },

            {
                "$inc": {
                    "balance":
                        -float(
                            amount
                        ),
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to save transaction"
            ),
        ) from error

    # =====================================================
    # SEND NOTIFICATIONS
    # =====================================================
    #
    # Notification problems should NOT cause
    # successful bank transfers to fail.
    #
    # Both notifications are sent concurrently.
    # =====================================================

    try:
        await asyncio.gather(

            # =============================================
            # SENDER
            # =============================================

            send_notification(
                user_id=
                    sender_id,

                title=
                    "Transfer Successful",

                body=(
                    f"You sent "
                    f"${float(amount):.2f} "
                    f"to {receiver_name}"
                ),

                data={
                    "type":
                        "transfer_sent",

                    "transaction_id":
                        transaction_id,

                    "amount":
                        f"{float(amount):.2f}",

                    "receiver_name":
                        receiver_name,
                },
            ),

            # =============================================
            # RECEIVER
            # =============================================

            send_notification(
                user_id=
                    receiver_id,

                title=
                    "Money Received",

                body=(
                    f"You received "
                    f"${float(amount):.2f} "
                    f"from {sender_name}"
                ),

                data={
                    "type":
                        "transfer_received",

                    "transaction_id":
                        transaction_id,

                    "amount":
                        f"{float(amount):.2f}",

                    "sender_name":
                        sender_name,
                },
            ),

            return_exceptions=True,
        )

    except Exception as error:
        print(
            "Notification error:",
            error,
        )

    # =====================================================
    # RESPONSE
    # =====================================================

    return {
        "success":
            True,

        "message":
            "Transfer successful",

        "data": {
            "transaction_id":
                transaction_id,

            "receiver_name":
                receiver_name,

            "receiver_account_number":
                receiver_account.get(
                    "account_number",
                    "",
                ),

            "amount":
                float(
                    amount
                ),

            "balance_before":
                float(
                    sender_before
                ),

            "balance_after":
                float(
                    sender_after
                ),

            "status":
                "success",

            "created_at":
                now,
        },
    }


# =========================================================
# TRANSFER HISTORY
# =========================================================

@router.get(
    "/history"
)
async def transfer_history(
    current_user: dict = Depends(
        get_current_user
    ),
):
    user_id = str(
        current_user[
            "_id"
        ]
    )

    cursor = db[
        "transactions"
    ].find(
        {
            "type":
                "transfer",

            "$or": [
                {
                    "sender_id":
                        user_id,
                },

                {
                    "receiver_id":
                        user_id,
                },
            ],
        }
    ).sort(
        "created_at",
        -1,
    )

    transactions = []

    async for item in cursor:
        is_sender = (
            item.get(
                "sender_id"
            )
            ==
            user_id
        )

        transactions.append(
            {
                "transaction_id":
                    item.get(
                        "transaction_id",
                        "",
                    ),

                "direction":
                    (
                        "sent"
                        if is_sender
                        else "received"
                    ),

                "sender_name":
                    item.get(
                        "sender_name",
                        "",
                    ),

                "receiver_name":
                    item.get(
                        "receiver_name",
                        "",
                    ),

                "sender_account_number":
                    item.get(
                        "sender_account_number",
                        "",
                    ),

                "receiver_account_number":
                    item.get(
                        "receiver_account_number",
                        "",
                    ),

                "amount":
                    float(
                        item.get(
                            "amount",
                            0,
                        )
                    ),

                "currency":
                    item.get(
                        "currency",
                        "USD",
                    ),

                "status":
                    item.get(
                        "status",
                        "",
                    ),

                "description":
                    item.get(
                        "description",
                        "",
                    ),

                "created_at":
                    item.get(
                        "created_at"
                    ),
            }
        )

    return {
        "success":
            True,

        "data":
            transactions,
    }

# =========================================================
# TRANSACTION DETAIL
# =========================================================

@router.get("/{transaction_id}")
async def get_transaction_detail(
    transaction_id: str,
    current_user: dict = Depends(
        get_current_user
    ),
):
    require_customer(
        current_user
    )

    user_id = str(
        current_user["_id"]
    )

    item = await db[
        "transactions"
    ].find_one(
        {
            "transaction_id":
                transaction_id,

            "$or": [
                {
                    "user_id":
                        user_id,
                },
                {
                    "sender_id":
                        user_id,
                },
                {
                    "receiver_id":
                        user_id,
                },
            ],
        }
    )

    if not item:
        raise HTTPException(
            status_code=404,
            detail="Transaction not found",
        )

    transaction_type = str(
        item.get(
            "type",
            "",
        )
    ).lower()

    direction = ""
    counterparty_name = ""
    counterparty_account = ""
    balance_before = 0.0
    balance_after = 0.0

    # =====================================================
    # DEPOSIT
    # =====================================================

    if transaction_type == "deposit":
        direction = "incoming"

        counterparty_name = (
            item.get(
                "agent_name",
                "",
            )
            or "Cash Deposit"
        )

        balance_before = float(
            item.get(
                "balance_before",
                0,
            )
            or 0
        )

        balance_after = float(
            item.get(
                "balance_after",
                0,
            )
            or 0
        )

    # =====================================================
    # TRANSFER
    # =====================================================

    elif transaction_type == "transfer":
        is_sender = (
            str(
                item.get(
                    "sender_id",
                    "",
                )
            )
            ==
            user_id
        )

        if is_sender:
            direction = "outgoing"

            counterparty_name = (
                item.get(
                    "receiver_name",
                    "",
                )
            )

            counterparty_account = (
                item.get(
                    "receiver_account_number",
                    "",
                )
            )

            balance_before = float(
                item.get(
                    "sender_balance_before",
                    0,
                )
                or 0
            )

            balance_after = float(
                item.get(
                    "sender_balance_after",
                    0,
                )
                or 0
            )

        else:
            direction = "incoming"

            counterparty_name = (
                item.get(
                    "sender_name",
                    "",
                )
            )

            counterparty_account = (
                item.get(
                    "sender_account_number",
                    "",
                )
            )

            balance_before = float(
                item.get(
                    "receiver_balance_before",
                    0,
                )
                or 0
            )

            balance_after = float(
                item.get(
                    "receiver_balance_after",
                    0,
                )
                or 0
            )

    # =====================================================
    # PAYMENT
    # =====================================================

    elif transaction_type == "payment":
        direction = "outgoing"

        counterparty_name = (
            item.get(
                "merchant_name",
                "",
            )
            or "Payment"
        )

        counterparty_account = (
            item.get(
                "merchant_account",
                "",
            )
        )

        balance_before = float(
            item.get(
                "balance_before",
                0,
            )
            or 0
        )

        balance_after = float(
            item.get(
                "balance_after",
                0,
            )
            or 0
        )

    return {
        "success": True,

        "data": {
            "id":
                str(
                    item["_id"]
                ),

            "transaction_id":
                item.get(
                    "transaction_id",
                    "",
                ),

            "type":
                transaction_type,

            "direction":
                direction,

            "amount":
                float(
                    item.get(
                        "amount",
                        0,
                    )
                    or 0
                ),

            "currency":
                item.get(
                    "currency",
                    "USD",
                ),

            "status":
                item.get(
                    "status",
                    "",
                ),

            "description":
                item.get(
                    "description",
                    "",
                ),

            "counterparty_name":
                counterparty_name,

            "counterparty_account":
                counterparty_account,

            "sender_name":
                item.get(
                    "sender_name",
                    "",
                ),

            "sender_account_number":
                item.get(
                    "sender_account_number",
                    "",
                ),

            "receiver_name":
                item.get(
                    "receiver_name",
                    "",
                ),

            "receiver_account_number":
                item.get(
                    "receiver_account_number",
                    "",
                ),

            "agent_name":
                item.get(
                    "agent_name",
                    "",
                ),

            "balance_before":
                balance_before,

            "balance_after":
                balance_after,

            "created_at":
                item.get(
                    "created_at",
                ),
        },
    }