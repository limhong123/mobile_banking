from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class UserRegister(BaseModel):
    first_name: str
    last_name: str
    phone_number: str

    pin: str = Field(
        ...,
        min_length=6,
        max_length=6,
    )

    @field_validator("pin")
    @classmethod
    def validate_pin(cls, value: str):
        if not value.isdigit():
            raise ValueError(
                "PIN must contain only numbers"
            )

        return value


class UserLogin(BaseModel):
    phone_number: str
    pin: str


class VerifyOTP(BaseModel):
    phone_number: str
    otp_code: str


class ResendOTP(BaseModel):
    phone_number: str


class UserOut(BaseModel):
    id: str
    first_name: str
    last_name: str
    phone_number: str

    is_verified: bool = False

    kyc_status: str = "not_submitted"

    created_at: datetime