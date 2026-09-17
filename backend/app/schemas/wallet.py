from pydantic import (
    BaseModel,
    Field,
)


class SystemFundCreate(BaseModel):
    amount: float = Field(
        ...,
        gt=0,
        le=1000000,
    )

    description: str | None = None


class AgentTopUpCreate(BaseModel):
    amount: float = Field(
        ...,
        gt=0,
        le=1000000,
    )

    description: str | None = None