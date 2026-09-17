from decimal import Decimal

from pydantic import (
    BaseModel,
    Field,
    field_validator,
)


class CashTransferCreate(BaseModel):
    sender_phone: str = Field(
        ...,
        min_length=8,
        max_length=30,
    )

    receiver_phone: str = Field(
        ...,
        min_length=8,
        max_length=30,
    )

    amount: Decimal = Field(
        ...,
        gt=Decimal("0"),
        le=Decimal("100000"),
    )

    @field_validator(
        "sender_phone",
        "receiver_phone",
    )
    @classmethod
    def clean_phone(
        cls,
        value: str,
    ):
        value = value.strip()

        if not value:
            raise ValueError(
                "Phone number is required"
            )

        return value


class CashPickupCheck(BaseModel):
    code: str = Field(
        ...,
        pattern=r"^\d{12}$",
    )

    receiver_phone: str = Field(
        ...,
        min_length=8,
        max_length=30,
    )


class CashPickupClaim(BaseModel):
    code: str = Field(
        ...,
        pattern=r"^\d{12}$",
    )

    receiver_phone: str = Field(
        ...,
        min_length=8,
        max_length=30,
    )


class AccountCodeCheck(BaseModel):
    code: str = Field(
        ...,
        pattern=r"^\d{12}$",
    )


class AccountCodeClaim(BaseModel):
    code: str = Field(
        ...,
        pattern=r"^\d{12}$",
    )