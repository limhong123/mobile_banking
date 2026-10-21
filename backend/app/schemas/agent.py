from datetime import date

from pydantic import (
    BaseModel,
    Field,
    field_validator,
)


class AgentCreate(BaseModel):
    first_name: str = Field(
        ...,
        min_length=1,
        max_length=100,
    )

    last_name: str = Field(
        ...,
        min_length=1,
        max_length=100,
    )

    phone_number: str = Field(
        ...,
        min_length=8,
        max_length=30,
    )

    nid_number: str = Field(
        ...,
        min_length=5,
        max_length=50,
    )

    date_of_birth: date

    gender: str = Field(
        ...,
        min_length=1,
        max_length=20,
    )

    address: str = Field(
        ...,
        min_length=2,
        max_length=300,
    )

    agent_code: str = Field(
        ...,
        min_length=2,
        max_length=50,
    )

    branch_name: str = Field(
        ...,
        min_length=2,
        max_length=150,
    )

    daily_transaction_limit: float | None = Field(
        default=None,
        ge=0,
    )

    pin: str = Field(
        ...,
        min_length=6,
        max_length=6,
    )

    @field_validator("pin")
    @classmethod
    def validate_pin(
        cls,
        value: str,
    ):
        if not value.isdigit():
            raise ValueError(
                "PIN must contain only digits"
            )

        return value

    @field_validator("gender")
    @classmethod
    def validate_gender(
        cls,
        value: str,
    ):
        value = (
            value
            .strip()
            .lower()
        )

        allowed = {
            "male",
            "female",
            "other",
        }

        if value not in allowed:
            raise ValueError(
                "Gender must be male, female or other"
            )

        return value

    @field_validator("agent_code")
    @classmethod
    def normalize_agent_code(
        cls,
        value: str,
    ):
        return (
            value
            .strip()
            .upper()
        )


class AgentUpdate(BaseModel):
    first_name: str | None = None

    last_name: str | None = None

    phone_number: str | None = None

    nid_number: str | None = None

    date_of_birth: date | None = None

    gender: str | None = None

    address: str | None = None

    agent_code: str | None = None

    branch_name: str | None = None

    daily_transaction_limit: float | None = Field(
        default=None,
        ge=0,
    )


class AgentResetPin(BaseModel):
    pin: str = Field(
        ...,
        min_length=6,
        max_length=6,
    )

    @field_validator("pin")
    @classmethod
    def validate_pin(
        cls,
        value: str,
    ):
        if not value.isdigit():
            raise ValueError(
                "PIN must contain only digits"
            )

        return value


class AgentDeposit(BaseModel):
    phone_number: str

    amount: float = Field(
        ...,
        gt=0,
    )

    description: str | None = None
