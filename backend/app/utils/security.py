import hashlib
import hmac

from passlib.context import CryptContext


pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
)


def hash_pin(pin: str) -> str:
    return pwd_context.hash(pin)


def verify_pin(
    plain_pin: str,
    hashed_pin: str,
) -> bool:
    return pwd_context.verify(
        plain_pin,
        hashed_pin,
    )


def hash_otp(otp: str) -> str:
    return hashlib.sha256(
        otp.encode("utf-8")
    ).hexdigest()


def verify_otp_hash(
    otp: str,
    stored_hash: str,
) -> bool:
    calculated_hash = hash_otp(otp)

    return hmac.compare_digest(
        calculated_hash,
        stored_hash,
    )