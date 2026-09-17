import firebase_admin

from firebase_admin import (
    credentials,
    messaging,
)

from app.database import db


# =========================================================
# FIREBASE INITIALIZE
# =========================================================

def initialize_firebase():
    if firebase_admin._apps:
        return

    cred = credentials.Certificate(
        "firebase-service-account.json"
    )

    firebase_admin.initialize_app(
        cred
    )


# =========================================================
# SEND FCM
# =========================================================

async def send_notification(
    user_id: str,
    title: str,
    body: str,
    data: dict | None = None,
):
    user = await db[
        "users"
    ].find_one(
        {
            "_id": __import__(
                "bson"
            ).ObjectId(
                user_id
            )
        }
    )

    if not user:
        return

    token = user.get(
        "fcm_token"
    )

    if not token:
        return

    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),

        data={
            str(key): str(value)
            for key, value in (
                data or {}
            ).items()
        },

        token=token,
    )

    try:
        response = messaging.send(
            message
        )

        print(
            "FCM notification sent:",
            response,
        )

    except Exception as error:
        print(
            "FCM notification error:",
            error,
        )