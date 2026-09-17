# app/schemas/user.py
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserRegister(BaseModel):
    first_name: str
    last_name: str
    phone_number: str
    pin: str = Field(..., min_length=6, max_length=6)  # 6-digit PIN

class UserLogin(BaseModel):
    phone_number: str
    pin: str

class UserOut(BaseModel):
    id: str
    first_name: str
    last_name: str
    phone_number: str
    is_verified: bool = False
    kyc_status: str = "not_submitted"
    created_at: datetime