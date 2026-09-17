from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)

from app.dependencies import (
    get_current_user,
)

from app.services.account_service import (
    ensure_customer_account,
)


router = APIRouter(
    prefix="/accounts",
    tags=["Accounts"],
)


def validate_customer(
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
                "KYC must be approved"
            ),
        )


@router.get("/me")
async def my_account(
    current_user: dict = Depends(
        get_current_user
    ),
):
    validate_customer(
        current_user
    )

    account = (
        await ensure_customer_account(
            str(
                current_user[
                    "_id"
                ]
            )
        )
    )

    return {
        "success":
            True,

        "data": {
            "account_number":
                account.get(
                    "account_number",
                    "",
                ),

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

            "is_frozen":
                account.get(
                    "is_frozen",
                    False,
                ),
        },
    }


@router.get("/my-qr")
async def my_qr(
    current_user: dict = Depends(
        get_current_user
    ),
):
    validate_customer(
        current_user
    )

    account = (
        await ensure_customer_account(
            str(
                current_user[
                    "_id"
                ]
            )
        )
    )

    full_name = (
        f"{current_user.get('first_name', '')} "
        f"{current_user.get('last_name', '')}"
    ).strip()

    return {
        "success":
            True,

        "data": {
            "customer_name":
                full_name,

            "account_number":
                account.get(
                    "account_number",
                    "",
                ),

            "qr_id":
                account.get(
                    "qr_id",
                    "",
                ),

            "qr_payload":
                account.get(
                    "qr_payload",
                    "",
                ),

            "qr_active":
                account.get(
                    "qr_active",
                    True,
                ),

            "currency":
                account.get(
                    "currency",
                    "USD",
                ),
        },
    }