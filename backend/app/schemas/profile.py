from pydantic import BaseModel
from typing import Optional


class ProfileUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None