from datetime import timedelta

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)

from pymongo import ReturnDocument

from app.database import db

from app.dependencies import (
    get_current_user,
)

from app.schemas.cash_transfer_schema import (
    AccountCodeCheck,
    AccountCodeClaim,
    CashPickupCheck,
    CashPickupClaim,
    CashTransferCreate,
)

from app.services.cash_transfer_service import (
    AGENT_WALLET_COLLECTION,
    CASH_TRANSFER_COLLECTION,
    CUSTOMER_ACCOUNT_COLLECTION,
    find_user_by_phone,
    full_name,
    generate_transfer_id,
    generate_unique_code,
    normalize_phone,
    utc_now,
)


router = APIRouter(
    prefix="/cash-transfers",
    tags=["Cash Transfers"],
)


# =========================================================
# REQUIRE AGENT
# =========================================================

async def require_agent(
    current_user: dict = Depends(
        get_current_user
    ),
):
    if current_user.get("role") != "agent":
        raise HTTPException(
            status_code=403,
            detail="Agent access required",
        )

    if not current_user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=403,
            detail="Agent account is disabled",
        )

    return current_user


# =========================================================
# REQUIRE CUSTOMER
# =========================================================

async def require_customer(
    current_user: dict = Depends(
        get_current_user
    ),
):
    if (
        current_user.get(
            "role",
            "user",
        )
        != "user"
    ):
        raise HTTPException(
            status_code=403,
            detail="Customer access required",
        )

    if not current_user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=403,
            detail="Customer account disabled",
        )

    if (
        current_user.get(
            "kyc_status"
        )
        != "approved"
    ):
        raise HTTPException(
            status_code=403,
            detail="KYC must be approved",
        )

    return current_user


# =========================================================
# CREATE CASH TRANSFER
# =========================================================

@router.post("/create")
async def create_cash_transfer(
    payload: CashTransferCreate,

    current_agent: dict = Depends(
        require_agent
    ),
):
    now = utc_now()

    amount = round(
        float(
            payload.amount
        ),
        2,
    )

    agent_id = str(
        current_agent["_id"]
    )

    sender_phone = normalize_phone(
        payload.sender_phone
    )

    receiver_phone = normalize_phone(
        payload.receiver_phone
    )

    # =====================================================
    # PREVENT SAME PHONE
    # =====================================================

    if (
        sender_phone
        == receiver_phone
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Sender and receiver phone "
                "cannot be the same"
            ),
        )

    # =====================================================
    # RECEIVER ACCOUNT OPTIONAL
    # =====================================================

    receiver_user = (
        await find_user_by_phone(
            receiver_phone
        )
    )

    receiver_user_id = None
    receiver_name = ""

    if receiver_user:
        receiver_user_id = str(
            receiver_user["_id"]
        )

        receiver_name = full_name(
            receiver_user
        )

    # =====================================================
    # DEDUCT ORIGIN AGENT WALLET
    # =====================================================

    updated_wallet = await db[
        AGENT_WALLET_COLLECTION
    ].find_one_and_update(
        {
            "agent_id":
                agent_id,

            "balance": {
                "$gte":
                    amount,
            },

            "is_frozen": {
                "$ne":
                    True,
            },
        },
        {
            "$inc": {
                "balance":
                    -amount,
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

    if not updated_wallet:
        raise HTTPException(
            status_code=400,
            detail=(
                "Insufficient agent balance "
                "or wallet is frozen"
            ),
        )

    # =====================================================
    # GENERATE 12-DIGIT NUMERIC CODE
    # =====================================================

    code = (
        await generate_unique_code()
    )

    transfer_id = (
        generate_transfer_id()
    )

    expires_at = (
        now
        + timedelta(
            hours=24
        )
    )

    origin_agent_name = (
        full_name(
            current_agent
        )
    )

    document = {
        "transfer_id":
            transfer_id,

        "code":
            code,

        "sender_phone":
            sender_phone,

        "receiver_phone":
            receiver_phone,

        "receiver_user_id":
            receiver_user_id,

        "receiver_name":
            receiver_name,

        "amount":
            amount,

        "currency":
            "USD",

        "origin_agent_id":
            agent_id,

        "origin_agent_name":
            origin_agent_name,

        "status":
            "pending",

        "claim_method":
            None,

        "claimed_by_user_id":
            None,

        "claimed_by_agent_id":
            None,

        "claimed_by_agent_name":
            None,

        "claimed_at":
            None,

        "created_at":
            now,

        "expires_at":
            expires_at,
    }

    try:
        await db[
            CASH_TRANSFER_COLLECTION
        ].insert_one(
            document
        )

    except Exception as error:
        await db[
            AGENT_WALLET_COLLECTION
        ].update_one(
            {
                "agent_id":
                    agent_id,
            },
            {
                "$inc": {
                    "balance":
                        amount,
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail="Unable to create transfer",
        ) from error

    return {
        "success": True,

        "message":
            "Cash transfer created",

        "data": {
            "transfer_id":
                transfer_id,

            "code":
                code,

            "sender_phone":
                sender_phone,

            "receiver_phone":
                receiver_phone,

            "receiver_has_account":
                receiver_user is not None,

            "receiver_name":
                receiver_name,

            "amount":
                amount,

            "currency":
                "USD",

            "status":
                "pending",

            "expires_at":
                expires_at,

            "agent_balance":
                float(
                    updated_wallet.get(
                        "balance",
                        0,
                    )
                ),
        },
    }


# =========================================================
# AGENT CHECK CODE FOR CASH PICKUP
# =========================================================

@router.post(
    "/cash-pickup/check"
)
async def check_cash_pickup(
    payload: CashPickupCheck,

    current_agent: dict = Depends(
        require_agent
    ),
):
    phone = normalize_phone(
        payload.receiver_phone
    )

    now = utc_now()

    transfer = await db[
        CASH_TRANSFER_COLLECTION
    ].find_one(
        {
            "code":
                payload.code,

            "receiver_phone":
                phone,

            "status":
                "pending",

            "expires_at": {
                "$gt":
                    now,
            },
        }
    )

    if not transfer:
        raise HTTPException(
            status_code=404,
            detail=(
                "Invalid, used or expired "
                "transfer code"
            ),
        )

    return {
        "success": True,

        "data": {
            "transfer_id":
                transfer.get(
                    "transfer_id"
                ),

            "code":
                transfer.get(
                    "code"
                ),

            "sender_phone":
                transfer.get(
                    "sender_phone"
                ),

            "receiver_phone":
                transfer.get(
                    "receiver_phone"
                ),

            "receiver_name":
                transfer.get(
                    "receiver_name",
                    "",
                ),

            "receiver_has_account":
                bool(
                    transfer.get(
                        "receiver_user_id"
                    )
                ),

            "amount":
                float(
                    transfer.get(
                        "amount",
                        0,
                    )
                ),

            "currency":
                transfer.get(
                    "currency",
                    "USD",
                ),

            "status":
                transfer.get(
                    "status",
                    "pending",
                ),

            "expires_at":
                transfer.get(
                    "expires_at"
                ),
        },
    }


# =========================================================
# AGENT CONFIRM CASH PAYOUT
# =========================================================

@router.post(
    "/cash-pickup/claim"
)
async def claim_cash_pickup(
    payload: CashPickupClaim,

    payout_agent: dict = Depends(
        require_agent
    ),
):
    now = utc_now()

    phone = normalize_phone(
        payload.receiver_phone
    )

    payout_agent_id = str(
        payout_agent["_id"]
    )

    payout_agent_name = (
        full_name(
            payout_agent
        )
    )

    transfer = await db[
        CASH_TRANSFER_COLLECTION
    ].find_one_and_update(
        {
            "code":
                payload.code,

            "receiver_phone":
                phone,

            "status":
                "pending",

            "expires_at": {
                "$gt":
                    now,
            },
        },
        {
            "$set": {
                "status":
                    "processing_cash",

                "claim_method":
                    "cash",

                "claimed_by_agent_id":
                    payout_agent_id,

                "claimed_by_agent_name":
                    payout_agent_name,

                "claimed_at":
                    now,
            },
        },
        return_document=(
            ReturnDocument.AFTER
        ),
    )

    if not transfer:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid, used or expired "
                "transfer code"
            ),
        )

    amount = float(
        transfer.get(
            "amount",
            0,
        )
    )

    try:
        wallet = await db[
            AGENT_WALLET_COLLECTION
        ].find_one_and_update(
            {
                "agent_id":
                    payout_agent_id,

                "is_frozen": {
                    "$ne":
                        True,
                },
            },
            {
                "$inc": {
                    "balance":
                        amount,
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

        if not wallet:
            raise Exception(
                "Payout agent wallet unavailable"
            )

    except Exception as error:
        await db[
            CASH_TRANSFER_COLLECTION
        ].update_one(
            {
                "_id":
                    transfer["_id"],
            },
            {
                "$set": {
                    "status":
                        "pending",

                    "claim_method":
                        None,

                    "claimed_by_agent_id":
                        None,

                    "claimed_by_agent_name":
                        None,

                    "claimed_at":
                        None,
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to complete cash payout"
            ),
        ) from error

    await db[
        CASH_TRANSFER_COLLECTION
    ].update_one(
        {
            "_id":
                transfer["_id"],
        },
        {
            "$set": {
                "status":
                    "claimed_cash",
            },
        },
    )

    transaction_id = (
        "PAYOUT-"
        + transfer[
            "transfer_id"
        ]
    )

    await db[
        "transactions"
    ].insert_one(
        {
            "transaction_id":
                transaction_id,

            "type":
                "cash_transfer",

            "cash_transfer_id":
                transfer[
                    "transfer_id"
                ],

            "code":
                transfer[
                    "code"
                ],

            "direction":
                "cash_pickup",

            "sender_phone":
                transfer.get(
                    "sender_phone",
                    "",
                ),

            "receiver_phone":
                phone,

            "receiver_user_id":
                transfer.get(
                    "receiver_user_id"
                ),

            "amount":
                amount,

            "currency":
                "USD",

            "claim_method":
                "cash",

            "payout_agent_id":
                payout_agent_id,

            "status":
                "success",

            "created_at":
                now,
        }
    )

    return {
        "success": True,

        "message":
            "Cash payout successful",

        "data": {
            "transfer_id":
                transfer[
                    "transfer_id"
                ],

            "transaction_id":
                transaction_id,

            "code":
                transfer[
                    "code"
                ],

            "receiver_phone":
                phone,

            "amount":
                amount,

            "status":
                "claimed_cash",

            "agent_balance":
                float(
                    wallet.get(
                        "balance",
                        0,
                    )
                ),
        },
    }


# =========================================================
# CUSTOMER CHECK CODE FOR ACCOUNT CREDIT
# =========================================================

@router.post(
    "/account/check"
)
async def check_account_claim(
    payload: AccountCodeCheck,

    current_user: dict = Depends(
        require_customer
    ),
):
    now = utc_now()

    user_phone = normalize_phone(
        current_user.get(
            "phone_number",
            "",
        )
    )

    user_id = str(
        current_user["_id"]
    )

    transfer = await db[
        CASH_TRANSFER_COLLECTION
    ].find_one(
        {
            "code":
                payload.code,

            "receiver_phone":
                user_phone,

            "status":
                "pending",

            "expires_at": {
                "$gt":
                    now,
            },
        }
    )

    if not transfer:
        raise HTTPException(
            status_code=404,
            detail=(
                "This code is invalid, used, "
                "expired or not assigned "
                "to your phone number"
            ),
        )

    stored_receiver_id = (
        transfer.get(
            "receiver_user_id"
        )
    )

    if (
        stored_receiver_id
        and stored_receiver_id
        != user_id
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "This transfer belongs "
                "to another account"
            ),
        )

    return {
        "success": True,

        "data": {
            "transfer_id":
                transfer.get(
                    "transfer_id"
                ),

            "code":
                transfer.get(
                    "code"
                ),

            "sender_phone":
                transfer.get(
                    "sender_phone",
                    "",
                ),

            "amount":
                float(
                    transfer.get(
                        "amount",
                        0,
                    )
                ),

            "currency":
                transfer.get(
                    "currency",
                    "USD",
                ),

            "expires_at":
                transfer.get(
                    "expires_at"
                ),
        },
    }


# =========================================================
# CUSTOMER CLAIM INTO ACCOUNT
# =========================================================

@router.post(
    "/account/claim"
)
async def claim_to_account(
    payload: AccountCodeClaim,

    current_user: dict = Depends(
        require_customer
    ),
):
    now = utc_now()

    user_id = str(
        current_user["_id"]
    )

    user_phone = normalize_phone(
        current_user.get(
            "phone_number",
            "",
        )
    )

    transfer = await db[
        CASH_TRANSFER_COLLECTION
    ].find_one_and_update(
        {
            "code":
                payload.code,

            "receiver_phone":
                user_phone,

            "status":
                "pending",

            "expires_at": {
                "$gt":
                    now,
            },
        },
        {
            "$set": {
                "status":
                    "processing_account",

                "claim_method":
                    "account",

                "claimed_by_user_id":
                    user_id,

                "claimed_at":
                    now,
            },
        },
        return_document=(
            ReturnDocument.AFTER
        ),
    )

    if not transfer:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid, used or expired code "
                "or phone number does not match"
            ),
        )

    stored_receiver_id = (
        transfer.get(
            "receiver_user_id"
        )
    )

    if (
        stored_receiver_id
        and stored_receiver_id
        != user_id
    ):
        await db[
            CASH_TRANSFER_COLLECTION
        ].update_one(
            {
                "_id":
                    transfer["_id"],
            },
            {
                "$set": {
                    "status":
                        "pending",

                    "claim_method":
                        None,

                    "claimed_by_user_id":
                        None,

                    "claimed_at":
                        None,
                },
            },
        )

        raise HTTPException(
            status_code=403,
            detail=(
                "This transfer belongs "
                "to another account"
            ),
        )

    amount = float(
        transfer.get(
            "amount",
            0,
        )
    )

    try:
        account = await db[
            CUSTOMER_ACCOUNT_COLLECTION
        ].find_one_and_update(
            {
                "user_id":
                    user_id,

                "is_frozen": {
                    "$ne":
                        True,
                },
            },
            {
                "$inc": {
                    "balance":
                        amount,
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

        if not account:
            raise Exception(
                "Customer wallet unavailable"
            )

    except Exception as error:
        await db[
            CASH_TRANSFER_COLLECTION
        ].update_one(
            {
                "_id":
                    transfer["_id"],
            },
            {
                "$set": {
                    "status":
                        "pending",

                    "claim_method":
                        None,

                    "claimed_by_user_id":
                        None,

                    "claimed_at":
                        None,
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to credit wallet"
            ),
        ) from error

    await db[
        CASH_TRANSFER_COLLECTION
    ].update_one(
        {
            "_id":
                transfer["_id"],
        },
        {
            "$set": {
                "status":
                    "claimed_account",

                "receiver_user_id":
                    user_id,

                "receiver_name":
                    full_name(
                        current_user
                    ),
            },
        },
    )

    transaction_id = (
        "CLAIM-"
        + transfer[
            "transfer_id"
        ]
    )

    await db[
        "transactions"
    ].insert_one(
        {
            "transaction_id":
                transaction_id,

            "type":
                "cash_transfer",

            "cash_transfer_id":
                transfer[
                    "transfer_id"
                ],

            "code":
                transfer[
                    "code"
                ],

            "direction":
                "received",

            "sender_phone":
                transfer.get(
                    "sender_phone",
                    "",
                ),

            "receiver_id":
                user_id,

            "receiver_phone":
                user_phone,

            "amount":
                amount,

            "currency":
                "USD",

            "claim_method":
                "account",

            "balance_after":
                float(
                    account.get(
                        "balance",
                        0,
                    )
                ),

            "status":
                "success",

            "created_at":
                now,
        }
    )

    return {
        "success": True,

        "message":
            "Money received successfully",

        "data": {
            "transfer_id":
                transfer[
                    "transfer_id"
                ],

            "transaction_id":
                transaction_id,

            "code":
                transfer[
                    "code"
                ],

            "amount":
                amount,

            "balance_after":
                float(
                    account.get(
                        "balance",
                        0,
                    )
                ),

            "status":
                "claimed_account",
        },
    }


# =========================================================
# AGENT HISTORY
# =========================================================

@router.get(
    "/agent/history"
)
async def agent_cash_transfer_history(
    current_agent: dict = Depends(
        require_agent
    ),
):
    agent_id = str(
        current_agent["_id"]
    )

    cursor = db[
        CASH_TRANSFER_COLLECTION
    ].find(
        {
            "$or": [
                {
                    "origin_agent_id":
                        agent_id,
                },
                {
                    "claimed_by_agent_id":
                        agent_id,
                },
            ],
        }
    ).sort(
        "created_at",
        -1,
    )

    data = []

    async for item in cursor:
        data.append(
            {
                "transfer_id":
                    item.get(
                        "transfer_id"
                    ),

                "code":
                    item.get(
                        "code"
                    ),

                "sender_phone":
                    item.get(
                        "sender_phone",
                        "",
                    ),

                "receiver_name":
                    item.get(
                        "receiver_name",
                        "",
                    ),

                "receiver_phone":
                    item.get(
                        "receiver_phone"
                    ),

                "amount":
                    float(
                        item.get(
                            "amount",
                            0,
                        )
                    ),

                "status":
                    item.get(
                        "status"
                    ),

                "claim_method":
                    item.get(
                        "claim_method"
                    ),

                "created_at":
                    item.get(
                        "created_at"
                    ),

                "claimed_at":
                    item.get(
                        "claimed_at"
                    ),
            }
        )

    return {
        "success":
            True,

        "data":
            data,
    }


# =========================================================
# CUSTOMER HISTORY
# =========================================================

@router.get(
    "/my-history"
)
async def my_cash_transfer_history(
    current_user: dict = Depends(
        require_customer
    ),
):
    phone = normalize_phone(
        current_user.get(
            "phone_number",
            "",
        )
    )

    cursor = db[
        CASH_TRANSFER_COLLECTION
    ].find(
        {
            "receiver_phone":
                phone,
        }
    ).sort(
        "created_at",
        -1,
    )

    data = []

    async for item in cursor:
        data.append(
            {
                "transfer_id":
                    item.get(
                        "transfer_id"
                    ),

                "sender_phone":
                    item.get(
                        "sender_phone",
                        "",
                    ),

                "receiver_phone":
                    item.get(
                        "receiver_phone",
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
                        "status"
                    ),

                "claim_method":
                    item.get(
                        "claim_method"
                    ),

                "created_at":
                    item.get(
                        "created_at"
                    ),

                "claimed_at":
                    item.get(
                        "claimed_at"
                    ),
            }
        )

    return {
        "success":
            True,

        "data":
            data,
    }