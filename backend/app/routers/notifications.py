from fastapi import (
    APIRouter,
    Depends,
)

from app.database import db
from app.dependencies import (
    get_current_user,
)


router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
)


@router.post("/fcm-token")
async def save_fcm_token(
    payload: dict,

    current_user: dict = Depends(
        get_current_user
    ),
):
    token = str(
        payload.get(
            "token",
            "",
        )
    ).strip()

    if not token:
        return {
            "success": False,
            "message": "FCM token required",
        }

    await db[
        "users"
    ].update_one(
        {
            "_id":
                current_user["_id"],
        },
        {
            "$set": {
                "fcm_token":
                    token,
            }
        },
    )

    return {
        "success": True,
        "message":
            "FCM token saved",
    }