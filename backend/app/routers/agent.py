from datetime import (
    datetime,
    timezone,
)
from decimal import Decimal
from uuid import uuid4

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

from app.schemas.agent import (
    AgentDeposit,
)

from app.services.otp_service import (
    normalize_phone,
)


router = APIRouter(
    prefix="/agent",
    tags=["Agent"],
)


# =========================================================
# REQUIRE AGENT
# =========================================================

async def require_agent(
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

    if role not in [
        "agent",
        "admin",
    ]:
        raise HTTPException(
            status_code=403,
            detail=(
                "Agent access required"
            ),
        )

    if not current_user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=403,
            detail=(
                "Agent account is disabled"
            ),
        )

    return current_user


# =========================================================
# TRANSACTION ID
# =========================================================

def generate_transaction_id():
    return (
        "DEP-"
        + uuid4()
        .hex[:12]
        .upper()
    )


# =========================================================
# TODAY START
# =========================================================

def get_today_start():
    now = datetime.now(
        timezone.utc
    )

    return now.replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )


# =========================================================
# AGENT DAILY DEPOSIT TOTAL
# =========================================================

async def get_agent_today_total(
    agent_id: str,
) -> float:
    today_start = (
        get_today_start()
    )

    pipeline = [
        {
            "$match": {
                "agent_id":
                    agent_id,

                "type":
                    "deposit",

                "status":
                    "success",

                "created_at": {
                    "$gte":
                        today_start,
                },
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

    total = 0.0

    async for item in db[
        "transactions"
    ].aggregate(
        pipeline
    ):
        total = float(
            item.get(
                "total",
                0,
            )
        )

    return total


# =========================================================
# AGENT PROFILE + WALLET
# =========================================================

@router.get("/me")
async def agent_me(
    current_agent: dict = Depends(
        require_agent,
    ),
):
    agent_id = str(
        current_agent["_id"]
    )

    wallet = await db[
        "agent_wallets"
    ].find_one(
        {
            "agent_id":
                agent_id,
        }
    )

    today_total = (
        await get_agent_today_total(
            agent_id
        )
    )

    daily_limit = float(
        current_agent.get(
            "daily_transaction_limit",
            5000,
        )
    )

    remaining_limit = max(
        daily_limit
        - today_total,
        0,
    )

    return {
        "success":
            True,

        "data": {
            "id":
                agent_id,

            "first_name":
                current_agent.get(
                    "first_name",
                    "",
                ),

            "last_name":
                current_agent.get(
                    "last_name",
                    "",
                ),

            "phone_number":
                current_agent.get(
                    "phone_number",
                    "",
                ),

            "nid_number":
                current_agent.get(
                    "nid_number",
                    "",
                ),

            "date_of_birth":
                current_agent.get(
                    "date_of_birth",
                ),

            "gender":
                current_agent.get(
                    "gender",
                    "",
                ),

            "address":
                current_agent.get(
                    "address",
                    "",
                ),

            "agent_code":
                current_agent.get(
                    "agent_code",
                    "",
                ),

            "branch_name":
                current_agent.get(
                    "branch_name",
                    "",
                ),

            "role":
                current_agent.get(
                    "role",
                    "",
                ),

            "is_active":
                current_agent.get(
                    "is_active",
                    True,
                ),

            "balance":
                float(
                    wallet.get(
                        "balance",
                        0,
                    )
                )
                if wallet
                else 0.0,

            "currency":
                wallet.get(
                    "currency",
                    "USD",
                )
                if wallet
                else "USD",

            "daily_transaction_limit":
                daily_limit,

            "today_transaction_amount":
                today_total,

            "remaining_daily_limit":
                remaining_limit,
        },
    }


# =========================================================
# SEARCH CUSTOMER
# =========================================================

@router.get("/customer")
async def search_customer(
    phone_number: str,

    current_agent: dict = Depends(
        require_agent,
    ),
):
    phone = normalize_phone(
        phone_number
    )

    customer = await db[
        "users"
    ].find_one(
        {
            "phone_number":
                phone,

            "role":
                "user",
        }
    )

    if not customer:
        raise HTTPException(
            status_code=404,
            detail=(
                "Customer not found"
            ),
        )

    if not customer.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Customer account is disabled"
            ),
        )

    if not customer.get(
        "is_verified",
        False,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Customer phone is not verified"
            ),
        )

    if customer.get(
        "kyc_status"
    ) != "approved":
        raise HTTPException(
            status_code=400,
            detail=(
                "Customer KYC is not approved"
            ),
        )

    customer_id = str(
        customer["_id"]
    )

    account = await db[
        "accounts"
    ].find_one(
        {
            "user_id":
                customer_id,
        }
    )

    return {
        "success":
            True,

        "data": {
            "id":
                customer_id,

            "first_name":
                customer.get(
                    "first_name",
                    "",
                ),

            "last_name":
                customer.get(
                    "last_name",
                    "",
                ),

            "phone_number":
                customer.get(
                    "phone_number",
                    "",
                ),

            "kyc_status":
                customer.get(
                    "kyc_status",
                    "not_submitted",
                ),

            "is_verified":
                customer.get(
                    "is_verified",
                    False,
                ),

            "is_active":
                customer.get(
                    "is_active",
                    True,
                ),

            "balance":
                float(
                    account.get(
                        "balance",
                        0,
                    )
                )
                if account
                else 0.0,

            "currency":
                account.get(
                    "currency",
                    "USD",
                )
                if account
                else "USD",
        },
    }


# =========================================================
# DEPOSIT TO CUSTOMER
# =========================================================

@router.post("/deposit")
async def agent_deposit(
    payload: AgentDeposit,

    current_agent: dict = Depends(
        require_agent,
    ),
):
    amount = Decimal(
        str(
            payload.amount
        )
    ).quantize(
        Decimal(
            "0.01"
        )
    )

    phone = normalize_phone(
        payload.phone_number
    )

    if amount <= 0:
        raise HTTPException(
            status_code=400,
            detail=(
                "Amount must be greater than 0"
            ),
        )

    if amount > Decimal(
        "100000.00"
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Maximum deposit amount is 100000"
            ),
        )

    agent_id = str(
        current_agent["_id"]
    )

    # =====================================================
    # DAILY LIMIT
    # =====================================================

    daily_limit = Decimal(
        str(
            current_agent.get(
                "daily_transaction_limit",
                5000,
            )
        )
    )

    today_total = Decimal(
        str(
            await get_agent_today_total(
                agent_id
            )
        )
    )

    projected_total = (
        today_total
        + amount
    )

    if projected_total > daily_limit:
        remaining = max(
            daily_limit
            - today_total,
            Decimal("0.00"),
        )

        raise HTTPException(
            status_code=400,
            detail=(
                "Daily transaction limit exceeded. "
                f"Remaining limit: ${remaining:.2f}"
            ),
        )

    # =====================================================
    # CUSTOMER
    # =====================================================

    customer = await db[
        "users"
    ].find_one(
        {
            "phone_number":
                phone,

            "role":
                "user",
        }
    )

    if not customer:
        raise HTTPException(
            status_code=404,
            detail=(
                "Customer not found"
            ),
        )

    if not customer.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Customer account is disabled"
            ),
        )

    if not customer.get(
        "is_verified",
        False,
    ):
        raise HTTPException(
            status_code=400,
            detail=(
                "Customer is not verified"
            ),
        )

    if customer.get(
        "kyc_status"
    ) != "approved":
        raise HTTPException(
            status_code=400,
            detail=(
                "Customer KYC is not approved"
            ),
        )

    customer_id = str(
        customer["_id"]
    )

    now = datetime.now(
        timezone.utc
    )

    # =====================================================
    # DEDUCT AGENT WALLET
    # =====================================================

    agent_wallet = await db[
        "agent_wallets"
    ].find_one_and_update(
        {
            "agent_id":
                agent_id,

            "balance": {
                "$gte":
                    float(
                        amount
                    ),
            },

            "is_frozen": {
                "$ne":
                    True,
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

    if not agent_wallet:
        wallet = await db[
            "agent_wallets"
        ].find_one(
            {
                "agent_id":
                    agent_id,
            }
        )

        if (
            wallet
            and wallet.get(
                "is_frozen",
                False,
            )
        ):
            raise HTTPException(
                status_code=403,
                detail=(
                    "Agent wallet is frozen"
                ),
            )

        raise HTTPException(
            status_code=400,
            detail=(
                "Insufficient agent balance"
            ),
        )

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
        + amount
    )

    # =====================================================
    # ADD CUSTOMER BALANCE
    # =====================================================

    try:
        customer_account = await db[
            "accounts"
        ].find_one_and_update(
            {
                "user_id":
                    customer_id,

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

                "$setOnInsert": {
                    "user_id":
                        customer_id,

                    "currency":
                        "USD",

                    "is_frozen":
                        False,

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
                        float(
                            amount
                        ),
                },

                "$set": {
                    "updated_at":
                        now,
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to update customer balance"
            ),
        ) from error

    if not customer_account:
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
                        float(
                            amount
                        ),
                },
            },
        )

        raise HTTPException(
            status_code=403,
            detail=(
                "Customer wallet is frozen"
            ),
        )

    customer_balance_after = Decimal(
        str(
            customer_account.get(
                "balance",
                0,
            )
        )
    )

    customer_balance_before = (
        customer_balance_after
        - amount
    )

    # =====================================================
    # TRANSACTION
    # =====================================================

    tx_id = (
        generate_transaction_id()
    )

    agent_name = (
        f"{current_agent.get('first_name', '')} "
        f"{current_agent.get('last_name', '')}"
    ).strip()

    customer_name = (
        f"{customer.get('first_name', '')} "
        f"{customer.get('last_name', '')}"
    ).strip()

    transaction = {
        "transaction_id":
            tx_id,

        "type":
            "deposit",

        "deposit_source":
            "agent_wallet",

        "customer_id":
            customer_id,

        "user_id":
            customer_id,

        "customer_name":
            customer_name,

        "customer_phone":
            phone,

        "agent_id":
            agent_id,

        "agent_name":
            agent_name,

        "agent_code":
            current_agent.get(
                "agent_code",
                "",
            ),

        "branch_name":
            current_agent.get(
                "branch_name",
                "",
            ),

        "amount":
            float(
                amount
            ),

        "currency":
            "USD",

        "agent_balance_before":
            float(
                agent_balance_before
            ),

        "agent_balance_after":
            float(
                agent_balance_after
            ),

        "balance_before":
            float(
                customer_balance_before
            ),

        "balance_after":
            float(
                customer_balance_after
            ),

        "status":
            "success",

        "description":
            (
                payload.description
                or "Agent deposit to customer"
            ),

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

        # Restore Agent wallet
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
                        float(
                            amount
                        ),
                },

                "$set": {
                    "updated_at":
                        now,
                },
            },
        )

        # Restore customer wallet
        await db[
            "accounts"
        ].update_one(
            {
                "_id":
                    customer_account[
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

                "$set": {
                    "updated_at":
                        now,
                },
            },
        )

        raise HTTPException(
            status_code=500,
            detail=(
                "Unable to save transaction"
            ),
        ) from error

    remaining_daily_limit = (
        daily_limit
        - projected_total
    )

    return {
        "success":
            True,

        "message":
            "Deposit successful",

        "data": {
            "transaction_id":
                tx_id,

            "customer_name":
                customer_name,

            "customer_phone":
                phone,

            "amount":
                float(
                    amount
                ),

            "agent_balance_before":
                float(
                    agent_balance_before
                ),

            "agent_balance_after":
                float(
                    agent_balance_after
                ),

            "balance_before":
                float(
                    customer_balance_before
                ),

            "balance_after":
                float(
                    customer_balance_after
                ),

            "daily_transaction_limit":
                float(
                    daily_limit
                ),

            "today_transaction_amount":
                float(
                    projected_total
                ),

            "remaining_daily_limit":
                float(
                    remaining_daily_limit
                ),

            "status":
                "success",
        },
    }


# =========================================================
# AGENT TRANSACTIONS
# =========================================================

@router.get("/transactions")
async def agent_transactions(
    current_agent: dict = Depends(
        require_agent,
    ),
):
    agent_id = str(
        current_agent["_id"]
    )

    cursor = (
        db[
            "transactions"
        ]
        .find(
            {
                "agent_id":
                    agent_id,

                "type":
                    "deposit",
            }
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(
            100
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

                "customer_name":
                    item.get(
                        "customer_name",
                        "",
                    ),

                "customer_phone":
                    item.get(
                        "customer_phone",
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

                "balance_before":
                    float(
                        item.get(
                            "balance_before",
                            0,
                        )
                    ),

                "balance_after":
                    float(
                        item.get(
                            "balance_after",
                            0,
                        )
                    ),

                "agent_balance_before":
                    float(
                        item.get(
                            "agent_balance_before",
                            0,
                        )
                    ),

                "agent_balance_after":
                    float(
                        item.get(
                            "agent_balance_after",
                            0,
                        )
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

        "count":
            len(
                results
            ),

        "data":
            results,
    }


# =========================================================
# AGENT DASHBOARD
# =========================================================

@router.get("/dashboard")
async def agent_dashboard(
    current_agent: dict = Depends(
        require_agent,
    ),
):
    agent_id = str(
        current_agent["_id"]
    )

    wallet = await db[
        "agent_wallets"
    ].find_one(
        {
            "agent_id":
                agent_id,
        }
    )

    wallet_balance = (
        float(
            wallet.get(
                "balance",
                0,
            )
        )
        if wallet
        else 0.0
    )

    currency = (
        wallet.get(
            "currency",
            "USD",
        )
        if wallet
        else "USD"
    )

    wallet_frozen = (
        wallet.get(
            "is_frozen",
            False,
        )
        if wallet
        else False
    )

    query = {
        "agent_id":
            agent_id,

        "type":
            "deposit",

        "status":
            "success",
    }

    total_transactions = await db[
        "transactions"
    ].count_documents(
        query
    )

    pipeline = [
        {
            "$match":
                query,
        },

        {
            "$group": {
                "_id":
                    None,

                "total_amount": {
                    "$sum":
                        "$amount",
                },
            }
        },
    ]

    total_amount = 0.0

    async for item in db[
        "transactions"
    ].aggregate(
        pipeline
    ):
        total_amount = float(
            item.get(
                "total_amount",
                0,
            )
        )

    today_total = (
        await get_agent_today_total(
            agent_id
        )
    )

    daily_limit = float(
        current_agent.get(
            "daily_transaction_limit",
            5000,
        )
    )

    remaining_limit = max(
        daily_limit
        - today_total,
        0,
    )

    recent_cursor = (
        db[
            "transactions"
        ]
        .find(
            query
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(
            5
        )
    )

    recent = []

    async for item in recent_cursor:
        recent.append(
            {
                "transaction_id":
                    item.get(
                        "transaction_id",
                        "",
                    ),

                "customer_name":
                    item.get(
                        "customer_name",
                        "",
                    ),

                "customer_phone":
                    item.get(
                        "customer_phone",
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

                "created_at":
                    item.get(
                        "created_at"
                    ),
            }
        )

    return {
        "success":
            True,

        "data": {
            "wallet_balance":
                wallet_balance,

            "currency":
                currency,

            "wallet_frozen":
                wallet_frozen,

            "daily_transaction_limit":
                daily_limit,

            "today_transaction_amount":
                today_total,

            "remaining_daily_limit":
                remaining_limit,

            "total_transactions":
                total_transactions,

            "total_deposit_amount":
                total_amount,

            "recent_transactions":
                recent,
        },
    }