from pydantic import BaseModel, Field
from typing import Optional


class DepositCreate(BaseModel):
    amount: float = Field(
        ...,
        gt=0,
        le=100000,
    )

    description: Optional[str] = None