from pydantic import (
    BaseModel,
    Field,
)


class BalanceAdjustmentRequest(BaseModel):
    amount: float = Field(
        ...,
        gt=0,
        description="Amount to adjust",
    )

    description: str | None = Field(
        default=None,
        max_length=500,
        description="Reason for adjustment",
    )

    reference: str | None = Field(
        default=None,
        max_length=100,
        description="Reference code or ticket ID",
    )
