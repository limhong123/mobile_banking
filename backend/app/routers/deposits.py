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


router = APIRouter(
    prefix="/deposits",
    tags=["Deposits"],
)


# =========================================================
# REQUIRE CUSTOMER
# =========================================================

async def require_customer(
    current_user: dict = Depends(
        get_current_user,
    ),
):
    role = str(
        current_user.get(
            "role",
            "user",
        )
    ).lower()

    if role != "user":
        raise HTTPException(
            status_code=(
                status.HTTP_403_FORBIDDEN
            ),
            detail=(
                "Customer access required"
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
                "Your account is disabled"
            ),
        )

    return current_user


# =========================================================
# GET CUSTOMER BALANCE
# =========================================================

@router.get("/balance")
async def get_balance(
    current_user: dict = Depends(
        require_customer,
    ),
):
    user_id = str(
        current_user["_id"]
    )

    account = await db[
        "accounts"
    ].find_one(
        {
            "user_id":
                user_id,
        }
    )

    # -----------------------------------------
    # Account not created yet
    # -----------------------------------------

    if account is None:
        return {
            "success":
                True,

            "balance":
                0.0,

            "currency":
                "USD",
        }

    return {
        "success":
            True,

        "balance":
            float(
                account.get(
                    "balance",
                    0,
                )
            ),

        "currency":
            account.get(
                "currency",
                "USD",
            ),
    }


# =========================================================
# GET CUSTOMER DEPOSIT HISTORY
# =========================================================

@router.get("/history")
async def get_deposit_history(
    current_user: dict = Depends(
        require_customer,
    ),
):
    user_id = str(
        current_user["_id"]
    )

    cursor = (
        db["transactions"]
        .find(
            {
                "user_id":
                    user_id,

                "type":
                    "deposit",
            }
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(100)
    )

    transactions = []

    async for item in cursor:

        transactions.append(
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
                        "deposit",
                    ),

                "deposit_source":
                    item.get(
                        "deposit_source",
                        "agent_cash",
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

                # Agent information
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

                "created_at":
                    item.get(
                        "created_at",
                    ),
            }
        )

    return {
        "success":
            True,

        "count":
            len(
                transactions
            ),

        "data":
            transactions,
    }


# =========================================================
# GET ONE DEPOSIT TRANSACTION
# =========================================================

@router.get(
    "/history/{transaction_id}"
)
async def get_deposit_detail(
    transaction_id: str,

    current_user: dict = Depends(
        require_customer,
    ),
):
    user_id = str(
        current_user["_id"]
    )

    transaction = await db[
        "transactions"
    ].find_one(
        {
            "transaction_id":
                transaction_id,

            "user_id":
                user_id,

            "type":
                "deposit",
        }
    )

    if not transaction:
        raise HTTPException(
            status_code=(
                status.HTTP_404_NOT_FOUND
            ),
            detail=(
                "Deposit transaction "
                "not found"
            ),
        )

    return {
        "success":
            True,

        "data": {
            "id":
                str(
                    transaction["_id"]
                ),

            "transaction_id":
                transaction.get(
                    "transaction_id",
                    "",
                ),

            "type":
                transaction.get(
                    "type",
                    "deposit",
                ),

            "deposit_source":
                transaction.get(
                    "deposit_source",
                    "agent_cash",
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

            "created_at":
                transaction.get(
                    "created_at",
                ),
        },
    }