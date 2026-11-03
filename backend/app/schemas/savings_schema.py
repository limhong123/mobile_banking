from pydantic import (
    BaseModel,
    Field,
)
from typing import Optional, Literal


class SavingsGlobalSettingsUpdate(BaseModel):
    min_deposit: float = Field(
        ...,
        gt=0,
        description="Global minimum deposit required for savings",
    )
    max_months: int = Field(
        default=48,
        ge=1,
        description="Maximum tenure in months allowed for terms",
    )


class SavingsTermCreate(BaseModel):
    label: str = Field(
        ...,
        min_length=1,
        max_length=60,
        description="User-facing term label (e.g. '1 Year', '6 Months')",
    )
    months: int = Field(
        ...,
        ge=1,
        description="Tenure in months",
    )
    rate: float = Field(
        ...,
        gt=0,
        description="Interest rate as decimal (e.g. 0.015 = 1.5% annual, 0.005 = 0.5% monthly)",
    )
    rate_unit: Literal["annual", "monthly"] = Field(
        ...,
        description="'annual' (% p.a.) or 'monthly' (% per month)",
    )
    min_amount: Optional[float] = Field(
        default=None,
        gt=0,
        description="Optional minimum amount override for this term",
    )
    active: bool = Field(
        default=True,
        description="Whether term is active and selectable by customers",
    )
    sort: Optional[int] = Field(
        default=None,
        description="Display sort order ascending; defaults to max(sort)+1 if omitted",
    )


class SavingsTermUpdate(BaseModel):
    label: Optional[str] = Field(default=None, min_length=1, max_length=60)
    months: Optional[int] = Field(default=None, ge=1)
    rate: Optional[float] = Field(default=None, gt=0)
    rate_unit: Optional[Literal["annual", "monthly"]] = None
    min_amount: Optional[float] = Field(default=None, gt=0)
    active: Optional[bool] = None
    sort: Optional[int] = None


class SavingsOpenRequest(BaseModel):
    term_id: str = Field(
        ...,
        description="ID of the savings term selected by customer",
    )
    amount: float = Field(
        ...,
        gt=0,
        description="Amount to deposit into savings",
    )
    notes: Optional[str] = None


# Backwards compatibility models
class SavingsRateSettings(BaseModel):
    monthly_rate: Optional[float] = Field(default=0.5, ge=0, le=100)
    yearly_rate: Optional[float] = Field(default=1.5, ge=0, le=100)
    yearly_rate_2yr: Optional[float] = Field(default=None, ge=0, le=100)
    yearly_rate_3yr: Optional[float] = Field(default=None, ge=0, le=100)
    min_deposit: float = Field(default=5.0, ge=0.1)
    max_months: Optional[int] = Field(default=48, ge=1)


class SavingsDepositCreate(BaseModel):
    amount: float = Field(..., gt=0)
    duration_type: Optional[str] = Field(default="yearly")
    duration_months: Optional[int] = Field(default=12, ge=1)
    term_id: Optional[str] = None
    notes: Optional[str] = None
