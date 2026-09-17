import secrets

import httpx

from app.config import settings


def normalize_phone(phone: str) -> str:
    phone = (
        phone
        .strip()
        .replace(" ", "")
        .replace("-", "")
    )

    if phone.startswith("+855"):
        return phone

    if phone.startswith("855"):
        return "+" + phone

    if phone.startswith("0"):
        return "+855" + phone[1:]

    return "+855" + phone


def generate_otp() -> str:
    return str(
        secrets.randbelow(900000)
        + 100000
    )


async def send_otp_sms(
    phone_number: str,
    otp: str,
) -> None:
    phone_number = normalize_phone(
        phone_number
    )

    to_number = phone_number.replace(
        "+",
        "",
    )

    url = (
        "https://cloudapi.plasgate.com/"
        "rest/send"
    )

    params = {
        "private_key": (
            settings.PLASGATE_PRIVATE_KEY
        ),
    }

    payload = {
        "sender": (
            settings.PLASGATE_SENDER
        ),
        "to": to_number,
        "content": (
            "Your KhemPay OTP code is: "
            f"{otp}. "
            "Valid for 5 minutes."
        ),
    }

    headers = {
        "Content-Type": "application/json",
        "X-Secret": (
            settings.PLASGATE_SECRET
        ),
    }

    async with httpx.AsyncClient(
        timeout=10.0,
    ) as client:
        response = await client.post(
            url,
            params=params,
            json=payload,
            headers=headers,
        )

    if response.status_code != 200:
        print(
            "[PlasGate Error] "
            f"{response.status_code}: "
            f"{response.text}"
        )

        raise RuntimeError(
            "Failed to send OTP"
        )

    print(
        f"OTP sent successfully to "
        f"{phone_number}"
    )