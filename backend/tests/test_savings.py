import os
import sys
from decimal import Decimal, ROUND_HALF_UP
from datetime import datetime, timezone
from bson import ObjectId
import pytest
from fastapi import HTTPException

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.database import db
from app.routers.savings import (
    calculate_interest,
    open_savings_deposit,
    payout_saving_deposit,
    admin_get_all_terms,
    admin_create_term,
    admin_update_term,
    admin_delete_term,
    admin_update_global_settings,
    get_customer_savings_terms,
)
from app.schemas.savings_schema import (
    SavingsTermCreate,
    SavingsTermUpdate,
    SavingsGlobalSettingsUpdate,
    SavingsOpenRequest,
)


# =========================================================
# 1. TEST SERVER-SIDE INTEREST CALCULATION (Decimal Formula)
# =========================================================
def test_interest_calculation():
    """
    Test server-side interest formula:
    - rate_unit 'annual':  interest = principal * rate * months / 12
    - rate_unit 'monthly': interest = principal * rate * months
    Round to 2 decimals only at the end.
    """
    # 1. Annual rate: $1,000 for 12 months at 0.015 (1.5% p.a.) gives $15.00
    interest, payout = calculate_interest(principal=1000.0, rate=0.015, months=12, rate_unit="annual")
    assert interest == 15.00
    assert payout == 1015.00

    # 2. Annual rate: $1,000 for 24 months at 0.020 (2.0% p.a.) gives $40.00
    interest, payout = calculate_interest(principal=1000.0, rate=0.020, months=24, rate_unit="annual")
    assert interest == 40.00
    assert payout == 1040.00

    # 3. Monthly rate: $1,000 for 1 month at 0.005 (0.5% per month) gives $5.00
    interest, payout = calculate_interest(principal=1000.0, rate=0.005, months=1, rate_unit="monthly")
    assert interest == 5.00
    assert payout == 1005.00

    # 4. Monthly rate: $1,000 for 3 months at 0.0055 (0.55% per month) gives $16.50
    interest, payout = calculate_interest(principal=1000.0, rate=0.0055, months=3, rate_unit="monthly")
    assert interest == 16.50
    assert payout == 1016.50


# =========================================================
# 2. TEST INSUFFICIENT BALANCE REJECTION
# =========================================================
@pytest.mark.asyncio
async def test_insufficient_balance_rejection():
    """
    Test that opening a deposit with amount > balance is rejected with 400 Insufficient balance.
    """
    now = datetime.now(timezone.utc)
    user_id = str(ObjectId())
    user = {
        "_id": ObjectId(user_id),
        "phone_number": "012111222",
        "role": "user",
        "is_active": True,
    }
    await db["users"].insert_one(user)

    account = {
        "_id": ObjectId(),
        "user_id": user_id,
        "account_number": "ACC-101",
        "balance": 200.0,
        "is_frozen": False,
        "created_at": now,
        "updated_at": now,
    }
    await db["accounts"].insert_one(account)

    term = {
        "_id": ObjectId(),
        "label": "1 Year Test",
        "months": 12,
        "rate": 0.015,
        "rate_unit": "annual",
        "min_amount": 5.0,
        "active": True,
        "sort": 1,
    }
    await db["savings_terms"].insert_one(term)

    try:
        # Try depositing $500 with only $200 in balance
        with pytest.raises(HTTPException) as exc_info:
            await open_savings_deposit(
                payload=SavingsOpenRequest(term_id=str(term["_id"]), amount=500.0),
                current_user=user,
            )
        assert exc_info.value.status_code == 400
        assert "Insufficient balance" in exc_info.value.detail
    finally:
        await db["users"].delete_one({"_id": user["_id"]})
        await db["accounts"].delete_one({"user_id": user_id})
        await db["savings_terms"].delete_one({"_id": term["_id"]})


# =========================================================
# 3. TEST SYSTEM WALLET SHORTAGE REJECTION
# =========================================================
@pytest.mark.asyncio
async def test_system_wallet_shortage_rejection():
    """
    Test that when System Wallet balance is lower than total projected interest,
    deposit is rejected with HTTP 400.
    """
    now = datetime.now(timezone.utc)
    user_id = str(ObjectId())
    user = {
        "_id": ObjectId(user_id),
        "phone_number": "012333444",
        "role": "user",
        "is_active": True,
    }
    await db["users"].insert_one(user)

    account = {
        "_id": ObjectId(),
        "user_id": user_id,
        "account_number": "ACC-102",
        "balance": 5000.0,
        "is_frozen": False,
        "created_at": now,
        "updated_at": now,
    }
    await db["accounts"].insert_one(account)

    term = {
        "_id": ObjectId(),
        "label": "1 Year Test",
        "months": 12,
        "rate": 0.020,  # 2.0%
        "rate_unit": "annual",
        "min_amount": 10.0,
        "active": True,
        "sort": 1,
    }
    await db["savings_terms"].insert_one(term)

    # Save original balance
    orig_wallet = await db["system_wallets"].find_one({"wallet_key": "main"})
    orig_bal = float(orig_wallet.get("balance", 8500.0)) if orig_wallet else 8500.0

    # Set System Wallet to only $10.00
    await db["system_wallets"].update_one(
        {"wallet_key": "main"},
        {"$set": {"balance": 10.0}},
        upsert=True,
    )

    try:
        # Depositing $1,000 for 1 year @ 2.0% requires $20.00 interest, but system wallet only has $10.00
        with pytest.raises(HTTPException) as exc_info:
            await open_savings_deposit(
                payload=SavingsOpenRequest(term_id=str(term["_id"]), amount=1000.0),
                current_user=user,
            )
        assert exc_info.value.status_code == 400
        assert "System Wallet has insufficient funds" in exc_info.value.detail
    finally:
        await db["users"].delete_one({"_id": user["_id"]})
        await db["accounts"].delete_one({"user_id": user_id})
        await db["savings_terms"].delete_one({"_id": term["_id"]})
        await db["system_wallets"].update_one(
            {"wallet_key": "main"},
            {"$set": {"balance": orig_bal}},
        )


# =========================================================
# 4. TEST DOUBLE PAYOUT PREVENTION & SYSTEM WALLET DEBIT
# =========================================================
@pytest.mark.asyncio
async def test_double_payout_prevention():
    """
    Test atomic status guard:
    - Deposit transitions from 'active' to 'matured'
    - Second payout attempt fails immediately
    - System Wallet is debited by interest
    - User account credited with principal + interest
    """
    now = datetime.now(timezone.utc)
    user_id = str(ObjectId())
    user = {
        "_id": ObjectId(user_id),
        "phone_number": "012555666",
        "role": "user",
        "is_active": True,
    }
    await db["users"].insert_one(user)

    account = {
        "_id": ObjectId(),
        "user_id": user_id,
        "account_number": "ACC-103",
        "balance": 1000.0,
        "is_frozen": False,
        "created_at": now,
        "updated_at": now,
    }
    await db["accounts"].insert_one(account)

    term = {
        "_id": ObjectId(),
        "label": "1 Year Special",
        "months": 12,
        "rate": 0.012,  # 1.2% p.a.
        "rate_unit": "annual",
        "min_amount": 10.0,
        "active": True,
        "sort": 1,
    }
    await db["savings_terms"].insert_one(term)

    # Save original balance
    orig_wallet_2 = await db["system_wallets"].find_one({"wallet_key": "main"})
    orig_bal_2 = float(orig_wallet_2.get("balance", 8500.0)) if orig_wallet_2 else 8500.0

    # System wallet funded with $500
    await db["system_wallets"].update_one(
        {"wallet_key": "main"},
        {"$set": {"balance": 500.0}},
        upsert=True,
    )

    sid = None
    try:
        # Deposit $1,000 for 1 year at 1.2% (interest = $12.00)
        dep_res = await open_savings_deposit(
            payload=SavingsOpenRequest(term_id=str(term["_id"]), amount=1000.0),
            current_user=user,
        )
        sid = dep_res["data"]["saving_id"]
        assert dep_res["data"]["interest_amount"] == 12.00
        assert dep_res["data"]["total_payout"] == 1012.00

        # User balance debited to 0
        acc_mid = await db["accounts"].find_one({"user_id": user_id})
        assert acc_mid["balance"] == 0.0

        # First payout: succeeds
        payout_res = await payout_saving_deposit(sid)
        assert payout_res["success"] is True
        assert payout_res["data"]["status"] == "matured"

        # User received 1012.00
        acc_after = await db["accounts"].find_one({"user_id": user_id})
        assert acc_after["balance"] == 1012.00

        # System wallet debited by $12.00 ($500 - $12 = $488)
        sys_wallet = await db["system_wallets"].find_one({"wallet_key": "main"})
        assert sys_wallet["balance"] == 488.00

        # Second payout: MUST FAIL (prevent double payout!)
        with pytest.raises(HTTPException) as exc_info:
            await payout_saving_deposit(sid)
        assert exc_info.value.status_code == 400
        assert "already matured" in exc_info.value.detail or "not found" in exc_info.value.detail
    finally:
        await db["users"].delete_one({"_id": user["_id"]})
        await db["accounts"].delete_one({"user_id": user_id})
        await db["savings_terms"].delete_one({"_id": term["_id"]})
        if sid:
            await db["savings"].delete_one({"saving_id": sid})
            await db["transactions"].delete_many({"saving_id": sid})
        await db["system_wallets"].update_one(
            {"wallet_key": "main"},
            {"$set": {"balance": orig_bal_2}},
        )


# =========================================================
# 5. TEST ADMIN TERMS CRUD, VALIDATION & AUDIT LOG
# =========================================================
@pytest.mark.asyncio
async def test_admin_terms_crud_validation_and_audit():
    """
    Test admin full control of terms and rates:
    - Create term with rate validation
    - Duplicate active months validation
    - Soft delete (DELETE -> active=false)
    - Audit log written on every change
    - Non-blocking warnings for rate inversions
    """
    admin = {
        "_id": ObjectId(),
        "phone_number": "012000111",
        "role": "admin",
        "is_active": True,
    }

    # 1. Reject invalid annual rate > 0.30
    with pytest.raises(HTTPException) as exc_info:
        await admin_create_term(
            payload=SavingsTermCreate(
                label="Greedy Term",
                months=12,
                rate=0.35,  # > 30%
                rate_unit="annual",
            ),
            current_admin=admin,
        )
    assert exc_info.value.status_code == 400
    assert "Annual interest rate must be" in exc_info.value.detail

    # 2. Reject invalid months > max_months (48)
    with pytest.raises(HTTPException) as exc_info:
        await admin_create_term(
            payload=SavingsTermCreate(
                label="Too Long Term",
                months=60,  # > 48
                rate=0.05,
                rate_unit="annual",
            ),
            current_admin=admin,
        )
    assert exc_info.value.status_code == 400
    assert "Duration months must be between" in exc_info.value.detail

    # 3. Create valid term: 18 Months @ 1.8% annual
    create_res = await admin_create_term(
        payload=SavingsTermCreate(
            label="18 Months Promo",
            months=18,
            rate=0.018,
            rate_unit="annual",
            min_amount=25.0,
            active=True,
            sort=10,
        ),
        current_admin=admin,
    )
    assert create_res["success"] is True
    term_id = create_res["data"]["id"]

    try:
        # 4. Reject duplicate ACTIVE months
        with pytest.raises(HTTPException) as exc_info:
            await admin_create_term(
                payload=SavingsTermCreate(
                    label="Duplicate 18 Mo",
                    months=18,
                    rate=0.022,
                    rate_unit="annual",
                    active=True,
                ),
                current_admin=admin,
            )
        assert exc_info.value.status_code == 400
        assert "An active savings term with 18 months already exists" in exc_info.value.detail

        # 5. Non-blocking warning: create a 20 months term with lower rate than 18 months (1.0% vs 1.8%)
        warn_res = await admin_create_term(
            payload=SavingsTermCreate(
                label="20 Months Inverted",
                months=20,
                rate=0.010,  # Lower than 18 months at 0.018!
                rate_unit="annual",
                active=True,
                sort=11,
            ),
            current_admin=admin,
        )
        assert warn_res["success"] is True
        assert any("is higher than" in w for w in warn_res["warnings"])
        term2_id = warn_res["data"]["id"]

        # 6. Soft delete term2 (DELETE -> active=false)
        del_res = await admin_delete_term(id=term2_id, current_admin=admin)
        assert del_res["success"] is True
        t2_doc = await db["savings_terms"].find_one({"_id": ObjectId(term2_id)})
        assert t2_doc["active"] is False  # Soft deleted!

        # 7. Check audit log was written
        audit = await db["savings_rate_audits"].find_one({"admin_id": str(admin["_id"])})
        assert audit is not None
        assert audit["action"] in ("create_term", "update_term", "delete_term")

        # 8. Customer terms check
        cust_terms = await get_customer_savings_terms()
        assert cust_terms["success"] is True
        # Term 1 (18 months) is active and in list
        active_ids = [t["id"] for t in cust_terms["data"]]
        assert term_id in active_ids
        assert term2_id not in active_ids  # Term 2 was deactivated!

    finally:
        await db["savings_terms"].delete_one({"_id": ObjectId(term_id)})
        if 'term2_id' in locals():
            await db["savings_terms"].delete_one({"_id": ObjectId(term2_id)})
        await db["savings_rate_audits"].delete_many({"admin_id": str(admin["_id"])})
