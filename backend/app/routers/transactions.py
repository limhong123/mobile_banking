from datetime import (
    datetime,
    timezone,
    timedelta,
)

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
)

from app.database import db
from app.dependencies import get_current_user


router = APIRouter(
    prefix="/transactions",
    tags=["Transactions"],
)


# =========================================================
# REQUIRE CUSTOMER
# =========================================================

def require_customer(
    user: dict,
):
    if (
        str(
            user.get(
                "role",
                "user",
            )
        ).lower()
        != "user"
    ):
        raise HTTPException(
            status_code=403,
            detail="Customer account required",
        )

    if not user.get(
        "is_active",
        True,
    ):
        raise HTTPException(
            status_code=403,
            detail="Account disabled",
        )


# =========================================================
# GET DATE RANGE
# =========================================================

def get_date_range(
    filter_type: str,
):
    now = datetime.now(
        timezone.utc
    )

    # =====================================================
    # DAY
    # =====================================================

    if filter_type == "day":
        start = datetime(
            now.year,
            now.month,
            now.day,
            tzinfo=timezone.utc,
        )

    # =====================================================
    # WEEK
    # Monday -> today
    # =====================================================

    elif filter_type == "week":
        start_of_day = datetime(
            now.year,
            now.month,
            now.day,
            tzinfo=timezone.utc,
        )

        start = (
            start_of_day
            - timedelta(
                days=now.weekday()
            )
        )

    # =====================================================
    # MONTH
    # =====================================================

    elif filter_type == "month":
        start = datetime(
            now.year,
            now.month,
            1,
            tzinfo=timezone.utc,
        )

    # =====================================================
    # YEAR
    # =====================================================

    elif filter_type == "year":
        start = datetime(
            now.year,
            1,
            1,
            tzinfo=timezone.utc,
        )

    else:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid filter. "
                "Use day, week, month or year."
            ),
        )

    return start, now


# =========================================================
# ANALYTICS
# =========================================================

@router.get("/analytics")
async def get_transaction_analytics(
    filter: str = Query(
        default="day",
    ),

    current_user: dict = Depends(
        get_current_user
    ),
):
    require_customer(
        current_user
    )

    filter_type = (
        filter
        .strip()
        .lower()
    )

    start_date, end_date = (
        get_date_range(
            filter_type
        )
    )

    user_id = str(
        current_user["_id"]
    )

    income = 0.0
    expense = 0.0

    income_count = 0
    expense_count = 0

    # =====================================================
    # FIND TRANSACTIONS
    # =====================================================

    cursor = db[
        "transactions"
    ].find(
        {
            "created_at": {
                "$gte":
                    start_date,

                "$lte":
                    end_date,
            },

            "status": {
                "$in": [
                    "success",
                    "completed",
                    "approved",
                ]
            },

            "$or": [

                # -----------------------------------------
                # Deposit
                # -----------------------------------------

                {
                    "user_id":
                        user_id,
                },

                # -----------------------------------------
                # Transfer sender
                # -----------------------------------------

                {
                    "sender_id":
                        user_id,
                },

                # -----------------------------------------
                # Transfer receiver
                # -----------------------------------------

                {
                    "receiver_id":
                        user_id,
                },
            ],
        }
    )

    # =====================================================
    # CALCULATE
    # =====================================================

    async for item in cursor:

        transaction_type = str(
            item.get(
                "type",
                "",
            )
        ).lower()

        amount = float(
            item.get(
                "amount",
                0,
            )
            or 0
        )

        # =================================================
        # DEPOSIT = INCOME
        # =================================================

        if (
            transaction_type
            == "deposit"
        ):
            if (
                str(
                    item.get(
                        "user_id",
                        "",
                    )
                )
                ==
                user_id
            ):
                income += amount
                income_count += 1

        # =================================================
        # TRANSFER
        # =================================================

        elif (
            transaction_type
            == "transfer"
        ):

            sender_id = str(
                item.get(
                    "sender_id",
                    "",
                )
            )

            receiver_id = str(
                item.get(
                    "receiver_id",
                    "",
                )
            )

            # ---------------------------------------------
            # Sent money = expense
            # ---------------------------------------------

            if sender_id == user_id:
                expense += amount
                expense_count += 1

            # ---------------------------------------------
            # Received money = income
            # ---------------------------------------------

            elif receiver_id == user_id:
                income += amount
                income_count += 1

        # =================================================
        # PAYMENT = EXPENSE
        # =================================================

        elif (
            transaction_type
            == "payment"
        ):
            if (
                str(
                    item.get(
                        "user_id",
                        "",
                    )
                )
                ==
                user_id
            ):
                expense += amount
                expense_count += 1

    # =====================================================
    # TOTAL
    # =====================================================

    total = (
        income
        + expense
    )

    if total > 0:
        income_percent = (
            income
            / total
            * 100
        )

        expense_percent = (
            expense
            / total
            * 100
        )

    else:
        income_percent = 0
        expense_percent = 0

    # =====================================================
    # RESPONSE
    # =====================================================

    return {
        "success":
            True,

        "filter":
            filter_type,

        "period": {
            "start":
                start_date,

            "end":
                end_date,
        },

        "data": {
            "income":
                round(
                    income,
                    2,
                ),

            "expense":
                round(
                    expense,
                    2,
                ),

            "total":
                round(
                    total,
                    2,
                ),

            "income_percent":
                round(
                    income_percent,
                    2,
                ),

            "expense_percent":
                round(
                    expense_percent,
                    2,
                ),

            "income_count":
                income_count,

            "expense_count":
                expense_count,
        },
    }


# =========================================================
# ALL TRANSACTION HISTORY
# =========================================================

@router.get("/history")
async def get_transaction_history(
    current_user: dict = Depends(
        get_current_user
    ),
):
    require_customer(current_user)

    user_id = str(
        current_user["_id"]
    )

    cursor = (
        db["transactions"]
        .find(
            {
                "$or": [
                    {
                        "user_id": user_id,
                    },
                    {
                        "sender_id": user_id,
                    },
                    {
                        "receiver_id": user_id,
                    },
                ]
            }
        )
        .sort(
            "created_at",
            -1,
        )
        .limit(100)
    )

    result = []

    async for item in cursor:

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

        # =================================================
        # DEPOSIT
        # =================================================

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

        # =================================================
        # TRANSFER
        # =================================================

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

        # =================================================
        # PAYMENT
        # =================================================

        elif transaction_type == "payment":

            direction = "outgoing"

            counterparty_name = (
                item.get(
                    "merchant_name",
                    "",
                )
                or "Payment"
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

        result.append(
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
            }
        )

    return {
        "success": True,
        "count": len(result),
        "data": result,
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

    # =====================================================
    # FIND TRANSACTION
    # =====================================================

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

    # =====================================================
    # TYPE
    # =====================================================

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

        # -------------------------------------------------
        # OUTGOING
        # -------------------------------------------------

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

        # -------------------------------------------------
        # INCOMING
        # -------------------------------------------------

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

    # =====================================================
    # RESPONSE
    # =====================================================

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

            # =============================================
            # COUNTERPARTY
            # =============================================

            "counterparty_name":
                counterparty_name,

            "counterparty_account":
                counterparty_account,

            # =============================================
            # SENDER
            # =============================================

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

            # =============================================
            # RECEIVER
            # =============================================

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

            # =============================================
            # DEPOSIT AGENT
            # =============================================

            "agent_name":
                item.get(
                    "agent_name",
                    "",
                ),

            # =============================================
            # BALANCE
            # =============================================

            "balance_before":
                balance_before,

            "balance_after":
                balance_after,

            # =============================================
            # DATE
            # =============================================

            "created_at":
                item.get(
                    "created_at",
                ),
        },
    }