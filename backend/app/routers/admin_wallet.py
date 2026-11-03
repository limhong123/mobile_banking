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
# (Full Ledger: Capital Funding, Agent Topups & Savings Interest)
# =========================================================

@router.get("/history")
async def system_wallet_history(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    results = []

    # 1. wallet_transactions (system_funding, agent_topup)
    cursor_wt = (
        db["wallet_transactions"]
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
        .limit(200)
    )

    async for item in cursor_wt:
        t_type = item.get("type", "")
        amount = float(item.get("amount", 0) or 0.0)
        c_at = item.get("created_at")
        c_at_str = c_at.isoformat() if hasattr(c_at, "isoformat") else str(c_at or "")

        if t_type == "system_funding":
            results.append(
                {
                    "id": str(item["_id"]),
                    "transaction_id": item.get("transaction_id", ""),
                    "type": "system_funding",
                    "category": "income",
                    "direction": "inflow",
                    "label": "Bank Capital Funding",
                    "sublabel": "Injected by Admin into Treasury",
                    "amount": amount,
                    "currency": item.get("currency", "USD"),
                    "agent_id": "",
                    "agent_name": "",
                    "saving_id": "",
                    "balance_before": item.get("balance_before"),
                    "balance_after": item.get("balance_after"),
                    "description": item.get("description", "Admin system wallet funding"),
                    "created_at": c_at_str,
                }
            )
        elif t_type == "agent_topup":
            results.append(
                {
                    "id": str(item["_id"]),
                    "transaction_id": item.get("transaction_id", ""),
                    "type": "agent_topup",
                    "category": "expenditure",
                    "direction": "outflow",
                    "label": "Agent Float Disbursement",
                    "sublabel": f"Recipient: {item.get('agent_name', 'Agent')}",
                    "amount": amount,
                    "currency": item.get("currency", "USD"),
                    "agent_id": item.get("agent_id", ""),
                    "agent_name": item.get("agent_name", ""),
                    "saving_id": "",
                    "balance_before": item.get("system_balance_before") or item.get("balance_before"),
                    "balance_after": item.get("system_balance_after") or item.get("balance_after"),
                    "description": item.get("description", "Agent float top up"),
                    "created_at": c_at_str,
                }
            )

    # 2. transactions with type == "system_interest_payout" (Customer Savings Interest Outflows)
    cursor_int = (
        db["transactions"]
        .find({"type": "system_interest_payout"})
        .sort("created_at", -1)
        .limit(200)
    )

    async for item in cursor_int:
        amount = float(item.get("amount", 0) or 0.0)
        c_at = item.get("created_at")
        c_at_str = c_at.isoformat() if hasattr(c_at, "isoformat") else str(c_at or "")
        sid = item.get("saving_id", "")
        results.append(
            {
                "id": str(item["_id"]),
                "transaction_id": item.get("transaction_id", ""),
                "type": "system_interest_payout",
                "category": "expenditure",
                "direction": "outflow",
                "label": "Savings Interest Paid",
                "sublabel": f"Customer Term Yield ({sid})" if sid else "Customer Savings Yield",
                "amount": amount,
                "currency": item.get("currency", "USD"),
                "agent_id": "",
                "agent_name": "",
                "saving_id": sid,
                "balance_before": item.get("balance_before"),
                "balance_after": item.get("balance_after"),
                "description": item.get("description", f"System Interest Payout for Savings ({sid})"),
                "created_at": c_at_str,
            }
        )

    # Sort combined ledger chronologically descending
    results.sort(
        key=lambda x: str(x.get("created_at") or ""),
        reverse=True,
    )

    return {
        "success": True,
        "data": results,
    }


# =========================================================
# BANK FINANCIAL SUMMARY
# (Income, Expenditure, Reserve & Customer Savings Hub)
# =========================================================

@router.get("/financial-summary")
async def get_financial_summary(
    current_admin: dict = Depends(
        require_admin,
    ),
):
    # 1. System Wallet Reserve Balance
    wallet = await db["system_wallets"].find_one({"wallet_key": "main"})
    bank_balance = float(wallet.get("balance", 0.0)) if wallet else 0.0
    currency = wallet.get("currency", "USD") if wallet else "USD"

    # 2. Funding Income & Agent Disbursements from wallet_transactions
    total_funding_income = 0.0
    funding_count = 0
    total_agent_disbursements = 0.0
    disbursement_count = 0

    cursor_wt = db["wallet_transactions"].find(
        {"status": "success"}
    ).sort("created_at", -1)

    recent_activities = []
    agent_topup_items = []
    async for tx in cursor_wt:
        t_type = tx.get("type", "")
        amount = float(tx.get("amount", 0.0) or 0.0)
        c_at = tx.get("created_at")
        c_at_str = c_at.isoformat() if hasattr(c_at, "isoformat") else str(c_at or "")

        if t_type == "system_funding":
            total_funding_income += amount
            funding_count += 1
            if len(recent_activities) < 20:
                recent_activities.append({
                    "id": str(tx["_id"]),
                    "transaction_id": tx.get("transaction_id", ""),
                    "category": "income",
                    "type": "system_funding",
                    "label": "Bank Capital Funding",
                    "sublabel": "Injected by Admin into Treasury",
                    "direction": "inflow",
                    "amount": amount,
                    "currency": currency,
                    "description": tx.get("description", "Admin system wallet funding"),
                    "created_at": c_at_str,
                })
        elif t_type == "agent_topup":
            total_agent_disbursements += amount
            disbursement_count += 1
            agent_topup_items.append({
                "transaction_id": tx.get("transaction_id", ""),
                "agent_name": tx.get("agent_name", "Agent"),
                "agent_id": str(tx.get("agent_id", "")),
                "amount": amount,
                "created_at": c_at_str,
                "description": tx.get("description", "Agent float top up"),
            })
            if len(recent_activities) < 20:
                recent_activities.append({
                    "id": str(tx["_id"]),
                    "transaction_id": tx.get("transaction_id", ""),
                    "category": "expenditure",
                    "type": "agent_topup",
                    "label": f"Agent Float Disbursement - {tx.get('agent_name', 'Agent')}",
                    "sublabel": "Cash for agent counter services",
                    "direction": "outflow",
                    "amount": amount,
                    "currency": currency,
                    "description": tx.get("description", "Agent float top up"),
                    "created_at": c_at_str,
                })

    # 3. System Interest Paid from transactions (type == "system_interest_payout")
    total_interest_paid = 0.0
    interest_payout_count = 0
    interest_payout_items = []

    cursor_int = db["transactions"].find(
        {"type": "system_interest_payout"}
    ).sort("created_at", -1)

    async for itx in cursor_int:
        amt = float(itx.get("amount", 0.0) or 0.0)
        total_interest_paid += amt
        interest_payout_count += 1
        c_at = itx.get("created_at")
        c_at_str = c_at.isoformat() if hasattr(c_at, "isoformat") else str(c_at or "")
        sid = itx.get("saving_id", "")
        interest_payout_items.append({
            "transaction_id": itx.get("transaction_id", ""),
            "saving_id": sid,
            "amount": amt,
            "created_at": c_at_str,
            "description": itx.get("description", f"Customer savings yield ({sid})"),
        })
        if len(recent_activities) < 30:
            recent_activities.append({
                "id": str(itx["_id"]),
                "transaction_id": itx.get("transaction_id", ""),
                "category": "expenditure",
                "type": "system_interest_payout",
                "label": f"Savings Interest Paid ({sid})" if sid else "Savings Interest Paid to Customer",
                "sublabel": "Guaranteed yield paid to customer on maturity",
                "direction": "outflow",
                "amount": amt,
                "currency": currency,
                "saving_id": sid,
                "description": itx.get("description", "Matured customer savings interest payout"),
                "created_at": c_at_str,
            })

    # Sort combined activities by created_at desc
    recent_activities.sort(
        key=lambda x: str(x.get("created_at") or ""),
        reverse=True
    )

    # 4. Customer Savings Overview
    total_active_savings = 0.0
    total_projected_interest = 0.0
    active_savings_count = 0
    total_completed_savings = 0.0
    completed_savings_count = 0
    unique_active_savers = set()

    recent_savings = []
    cursor_sav = db["savings"].find({}).sort("created_at", -1)
    async for s in cursor_sav:
        status_val = s.get("status", "active")
        principal = float(s.get("principal") or s.get("principal_amount", 0.0) or 0.0)
        interest = float(s.get("interest_amount") or s.get("expected_interest", 0.0) or 0.0)
        uid = str(s.get("user_id", ""))

        if status_val == "active":
            total_active_savings += principal
            total_projected_interest += interest
            active_savings_count += 1
            if uid:
                unique_active_savers.add(uid)
        elif status_val == "completed":
            total_completed_savings += principal
            completed_savings_count += 1

        if len(recent_savings) < 5:
            m_date = s.get("maturity_date")
            c_date = s.get("created_at")
            recent_savings.append({
                "id": str(s["_id"]),
                "saving_id": s.get("saving_id", ""),
                "user_name": s.get("user_name", "Customer Saver"),
                "phone_number": s.get("phone_number", ""),
                "principal": principal,
                "term": s.get("term", ""),
                "rate": float(s.get("rate") or s.get("interest_rate", 0.0) or 0.0),
                "interest_amount": interest,
                "total_payout": float(s.get("total_payout", principal + interest) or 0.0),
                "status": status_val,
                "maturity_date": m_date.isoformat() if hasattr(m_date, "isoformat") else str(m_date or ""),
                "created_at": c_date.isoformat() if hasattr(c_date, "isoformat") else str(c_date or ""),
            })

    total_income = total_funding_income
    total_expenditure = total_agent_disbursements + total_interest_paid
    net_flow = total_income - total_expenditure

    # Reserve coverage ratio (safety check)
    reserve_coverage = (
        round((bank_balance / total_projected_interest) * 100, 1)
        if total_projected_interest > 0
        else 100.0
    )

    # Detailed Reconciliation Breakdown
    agent_pct = round((total_agent_disbursements / total_expenditure * 100), 1) if total_expenditure > 0 else 0.0
    interest_pct = round((total_interest_paid / total_expenditure * 100), 1) if total_expenditure > 0 else 0.0
    expected_balance = round(total_income - total_expenditure, 2)
    variance = round(bank_balance - expected_balance, 2)

    return {
        "success": True,
        "data": {
            "bank_balance": round(bank_balance, 2),
            "currency": currency,
            "income": {
                "total": round(total_income, 2),
                "system_funding": round(total_funding_income, 2),
                "funding_count": funding_count,
            },
            "expenditure": {
                "total": round(total_expenditure, 2),
                "agent_disbursements": round(total_agent_disbursements, 2),
                "disbursement_count": disbursement_count,
                "savings_interest_paid": round(total_interest_paid, 2),
                "interest_payout_count": interest_payout_count,
                "agent_topup_items": agent_topup_items,
                "interest_payout_items": interest_payout_items,
                "breakdown": [
                    {
                        "id": "agent_disbursements",
                        "label": "Agent Float Disbursements",
                        "sublabel": "Capital transferred to agent branch counters",
                        "amount": round(total_agent_disbursements, 2),
                        "count": disbursement_count,
                        "percentage": agent_pct,
                        "color": "rose",
                    },
                    {
                        "id": "savings_interest",
                        "label": "Customer Savings Interest Paid",
                        "sublabel": "Guaranteed yield paid out to savers upon term maturity",
                        "amount": round(total_interest_paid, 2),
                        "count": interest_payout_count,
                        "percentage": interest_pct,
                        "color": "amber",
                    },
                ],
                "reconciliation": {
                    "total_income": round(total_income, 2),
                    "total_expenditure": round(total_expenditure, 2),
                    "expected_balance": expected_balance,
                    "actual_balance": round(bank_balance, 2),
                    "variance": variance,
                    "is_synced": abs(variance) < 0.001,
                    "formula_text": f"${total_income:,.2f} (Funded) - ${total_agent_disbursements:,.2f} (Agent Float) - ${total_interest_paid:,.2f} (Savings Interest) = ${expected_balance:,.2f} Net Balance",
                    "explanation": f"Total Outflow (${total_expenditure:,.2f}) = Agent Disbursements (${total_agent_disbursements:,.2f}) + Customer Savings Interest Paid (${total_interest_paid:,.2f}).",
                },
            },
            "net_flow": round(net_flow, 2),
            "savings": {
                "active_savings_volume": round(total_active_savings, 2),
                "active_savings_count": active_savings_count,
                "projected_interest_liability": round(total_projected_interest, 2),
                "completed_savings_volume": round(total_completed_savings, 2),
                "completed_savings_count": completed_savings_count,
                "unique_savers_count": len(unique_active_savers),
                "reserve_coverage_ratio": reserve_coverage,
                "recent_savings": recent_savings,
            },
            "recent_activities": recent_activities[:15],
        },
    }


# =========================================================
# RECONCILE SYSTEM WALLET
# (Admin tool to sync reserve or clear orphan test payouts)
# =========================================================

@router.post("/reconcile")
async def reconcile_system_wallet(
    payload: dict,
    current_admin: dict = Depends(require_admin),
):
    action = payload.get("action", "sync_balance")
    now = datetime.now(timezone.utc)

    if action == "sync_balance":
        # Calculate true net flow: Total Inflow - Total Outflow
        total_income = 0.0
        async for tx in db["wallet_transactions"].find({"type": "system_funding", "status": "success"}):
            total_income += float(tx.get("amount", 0.0) or 0.0)

        total_agent = 0.0
        async for tx in db["wallet_transactions"].find({"type": "agent_topup", "status": "success"}):
            total_agent += float(tx.get("amount", 0.0) or 0.0)

        total_interest = 0.0
        async for tx in db["transactions"].find({"type": "system_interest_payout"}):
            total_interest += float(tx.get("amount", 0.0) or 0.0)

        reconciled = round(total_income - (total_agent + total_interest), 2)
        await db["system_wallets"].update_one(
            {"wallet_key": "main"},
            {"$set": {"balance": reconciled, "updated_at": now}},
            upsert=True,
        )
        return {
            "success": True,
            "message": f"System wallet balance synced to net cash flow (${reconciled:,.2f}).",
            "data": {"balance": reconciled},
        }

    elif action == "clear_test_payouts":
        res = await db["transactions"].delete_many({"type": "system_interest_payout"})
        return {
            "success": True,
            "message": f"Cleared {res.deleted_count} test savings interest records. Total Outflow is now aligned with Agent Disbursements.",
            "data": {"deleted_count": res.deleted_count},
        }

    elif action == "set_balance":
        new_bal = float(payload.get("balance", 8500.0))
        await db["system_wallets"].update_one(
            {"wallet_key": "main"},
            {"$set": {"balance": new_bal, "updated_at": now}},
            upsert=True,
        )
        return {
            "success": True,
            "message": f"System wallet balance set to ${new_bal:,.2f}.",
            "data": {"balance": new_bal},
        }

    raise HTTPException(status_code=400, detail="Invalid reconciliation action")



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