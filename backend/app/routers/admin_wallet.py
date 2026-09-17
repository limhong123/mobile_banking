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
    status,
)

from pymongo import (
    ReturnDocument,
)

from app.database import db

from app.dependencies import (
    get_current_user,
)

from app.schemas.wallet import (
    AgentTopUpCreate,
    SystemFundCreate,
)


router = APIRouter(
    prefix="/admin/wallet",
    tags=["Admin Wallet"],
)


# =========================================================
# REQUIRE ADMIN
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
            status_code=403,
            detail=(
                "Admin account is disabled"
            ),
        )

    return current_user


# =========================================================
# TRANSACTION ID
# =========================================================

def generate_wallet_transaction_id(
    prefix: str,
):
    return (
        f"{prefix}-"
        f"{uuid4().hex[:12].upper()}"
    )


# =========================================================
# GET SYSTEM WALLET
# =========================================================

@router.get("")
async def get_system_wallet(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    wallet = await db[
        "system_wallets"
    ].find_one(
        {
            "wallet_key":
                "main",
        }
    )

    if not wallet:
        return {
            "success":
                True,

            "data": {
                "balance":
                    0.0,

                "currency":
                    "USD",
            },
        }

    return {
        "success":
            True,

        "data": {
            "id":
                str(
                    wallet["_id"]
                ),

            "balance":
                float(
                    wallet.get(
                        "balance",
                        0,
                    )
                ),

            "currency":
                wallet.get(
                    "currency",
                    "USD",
                ),

            "updated_at":
                wallet.get(
                    "updated_at"
                ),
        },
    }


# =========================================================
# FUND SYSTEM WALLET
# Demo / Development funding
# =========================================================

@router.post("/fund")
async def fund_system_wallet(
    payload: SystemFundCreate,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    amount = Decimal(
        str(payload.amount)
    ).quantize(
        Decimal("0.01")
    )

    if amount <= 0:
        raise HTTPException(
            status_code=400,
            detail=(
                "Amount must be greater than 0"
            ),
        )

    now = datetime.now(
        timezone.utc
    )

    wallet = await db[
        "system_wallets"
    ].find_one_and_update(
        {
            "wallet_key":
                "main",
        },

        {
            "$inc": {
                "balance":
                    float(amount),
            },

            "$set": {
                "updated_at":
                    now,
            },

            "$setOnInsert": {
                "wallet_key":
                    "main",

                "currency":
                    "USD",

                "created_at":
                    now,
            },
        },

        upsert=True,

        return_document=(
            ReturnDocument.AFTER
        ),
    )

    if not wallet:
        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to fund system wallet"
            ),
        )

    balance_after = Decimal(
        str(
            wallet.get(
                "balance",
                0,
            )
        )
    )

    balance_before = (
        balance_after
        - amount
    )

    tx_id = (
        generate_wallet_transaction_id(
            "SYS"
        )
    )

    transaction = {
        "transaction_id":
            tx_id,

        "type":
            "system_funding",

        "amount":
            float(amount),

        "currency":
            wallet.get(
                "currency",
                "USD",
            ),

        "balance_before":
            float(
                balance_before
            ),

        "balance_after":
            float(
                balance_after
            ),

        "status":
            "success",

        "admin_id":
            str(
                current_admin["_id"]
            ),

        "admin_name":
            (
                f"{current_admin.get('first_name', '')} "
                f"{current_admin.get('last_name', '')}"
            ).strip(),

        "description":
            (
                payload.description
                or "System wallet funding"
            ),

        "created_at":
            now,
    }

    try:
        await db[
            "wallet_transactions"
        ].insert_one(
            transaction
        )

    except Exception as error:

        # rollback balance if history save fails
        await db[
            "system_wallets"
        ].update_one(
            {
                "_id":
                    wallet["_id"],
            },
            {
                "$inc": {
                    "balance":
                        -float(amount),
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to save funding transaction"
            ),
        ) from error

    return {
        "success":
            True,

        "message":
            "System wallet funded successfully",

        "data": {
            "transaction_id":
                tx_id,

            "amount":
                float(amount),

            "balance_before":
                float(
                    balance_before
                ),

            "balance_after":
                float(
                    balance_after
                ),

            "currency":
                wallet.get(
                    "currency",
                    "USD",
                ),
        },
    }


# =========================================================
# SYSTEM WALLET HISTORY
# =========================================================

@router.get("/history")
async def system_wallet_history(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    cursor = (
        db[
            "wallet_transactions"
        ]
        .find(
            {
                "type": {
                    "$in": [
                        "system_funding",
                        "agent_topup",
                    ]
                }
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

    async for item in cursor:

        results.append(
            {
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
                    item.get(
                        "type",
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

                "agent_id":
                    item.get(
                        "agent_id",
                        "",
                    ),

                "agent_name":
                    item.get(
                        "agent_name",
                        "",
                    ),

                "balance_before":
                    item.get(
                        "balance_before",
                    ),

                "balance_after":
                    item.get(
                        "balance_after",
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
            results,
    }


# =========================================================
# TOP UP AGENT
# =========================================================

@router.post(
    "/agents/{agent_id}/topup"
)
async def topup_agent(
    agent_id: str,

    payload: AgentTopUpCreate,

    current_admin: dict = Depends(
        require_admin,
    ),
):
    try:
        agent_object_id = (
            ObjectId(
                agent_id
            )
        )

    except Exception as error:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid agent ID"
            ),
        ) from error

    amount = Decimal(
        str(payload.amount)
    ).quantize(
        Decimal("0.01")
    )

    if amount <= 0:
        raise HTTPException(
            status_code=400,
            detail=(
                "Top up amount must be greater than 0"
            ),
        )

    # =========================================
    # Find Agent
    # =========================================

    agent = await db[
        "users"
    ].find_one(
        {
            "_id":
                agent_object_id,

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

    if not agent.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Agent account is disabled"
            ),
        )

    now = datetime.now(
        timezone.utc
    )

    # =========================================
    # DEDUCT SYSTEM WALLET
    # balance must be >= amount
    # =========================================

    system_wallet = await db[
        "system_wallets"
    ].find_one_and_update(
        {
            "wallet_key":
                "main",

            "balance": {
                "$gte":
                    float(amount),
            },
        },

        {
            "$inc": {
                "balance":
                    -float(amount),
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

    if not system_wallet:
        raise HTTPException(
            status_code=400,
            detail=(
                "Insufficient system wallet balance"
            ),
        )

    system_balance_after = Decimal(
        str(
            system_wallet.get(
                "balance",
                0,
            )
        )
    )

    system_balance_before = (
        system_balance_after
        + amount
    )

    # =========================================
    # ADD AGENT BALANCE
    # =========================================

    try:
        agent_wallet = await db[
            "agent_wallets"
        ].find_one_and_update(
            {
                "agent_id":
                    agent_id,
            },

            {
                "$inc": {
                    "balance":
                        float(amount),
                },

                "$set": {
                    "updated_at":
                        now,
                },

                "$setOnInsert": {
                    "agent_id":
                        agent_id,

                    "currency":
                        "USD",

                    "created_at":
                        now,
                },
            },

            upsert=True,

            return_document=(
                ReturnDocument.AFTER
            ),
        )

    except Exception as error:

        # Restore system balance
        await db[
            "system_wallets"
        ].update_one(
            {
                "_id":
                    system_wallet[
                        "_id"
                    ],
            },
            {
                "$inc": {
                    "balance":
                        float(amount),
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to update agent wallet"
            ),
        ) from error

    agent_balance_after = Decimal(
        str(
            agent_wallet.get(
                "balance",
                0,
            )
        )
    )

    agent_balance_before = (
        agent_balance_after
        - amount
    )

    tx_id = (
        generate_wallet_transaction_id(
            "TOP"
        )
    )

    agent_name = (
        f"{agent.get('first_name', '')} "
        f"{agent.get('last_name', '')}"
    ).strip()

    transaction = {
        "transaction_id":
            tx_id,

        "type":
            "agent_topup",

        "agent_id":
            agent_id,

        "agent_name":
            agent_name,

        "amount":
            float(amount),

        "currency":
            "USD",

        "system_balance_before":
            float(
                system_balance_before
            ),

        "system_balance_after":
            float(
                system_balance_after
            ),

        "agent_balance_before":
            float(
                agent_balance_before
            ),

        "agent_balance_after":
            float(
                agent_balance_after
            ),

        "status":
            "success",

        "admin_id":
            str(
                current_admin["_id"]
            ),

        "description":
            (
                payload.description
                or "Agent wallet top up"
            ),

        "created_at":
            now,
    }

    try:
        await db[
            "wallet_transactions"
        ].insert_one(
            transaction
        )

    except Exception as error:

        # Roll back both balances
        await db[
            "agent_wallets"
        ].update_one(
            {
                "_id":
                    agent_wallet[
                        "_id"
                    ],
            },
            {
                "$inc": {
                    "balance":
                        -float(amount),
                },
            },
        )

        await db[
            "system_wallets"
        ].update_one(
            {
                "_id":
                    system_wallet[
                        "_id"
                    ],
            },
            {
                "$inc": {
                    "balance":
                        float(amount),
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to save top up transaction"
            ),
        ) from error

    return {
        "success":
            True,

        "message":
            "Agent top up successful",

        "data": {
            "transaction_id":
                tx_id,

            "agent_id":
                agent_id,

            "agent_name":
                agent_name,

            "amount":
                float(amount),

            "system_balance_after":
                float(
                    system_balance_after
                ),

            "agent_balance_after":
                float(
                    agent_balance_after
                ),

            "currency":
                "USD",
        },
    }