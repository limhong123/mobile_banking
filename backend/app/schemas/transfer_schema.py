from pydantic import (
    BaseModel,
    Field,
)


class ResolveQrRequest(
    BaseModel
):
    qr_payload: str = Field(
        ...,
        min_length=5,
        max_length=200,
    )


class ResolveAccountRequest(
    BaseModel
):
    account_number: str = Field(
        ...,
        min_length=4,
        max_length=50,
    )


class TransferCreate(
    BaseModel
):
    receiver_account_number: (
        str | None
    ) = None

    receiver_qr_id: (
        str | None
    ) = None

    amount: float = Field(
        ...,
        gt=0,
        le=100000,
    )

    description: str | None = Field(
        default=None,
        max_length=300,
    )