from sqlalchemy import (
    Column,
    Integer,
    String,
    ForeignKey,
    Numeric,
    DateTime,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.database.db import Base


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    account_id = Column(
        Integer,
        ForeignKey("accounts.id"),
        nullable=False,
        index=True,
    )

    transaction_id = Column(
        String(100),
        nullable=False,
        unique=True,
        index=True,
    )

    transaction_type = Column(
        String(30),
        nullable=False,
    )

    amount = Column(
        Numeric(18, 2),
        nullable=False,
    )

    balance_before = Column(
        Numeric(18, 2),
        nullable=False,
    )

    balance_after = Column(
        Numeric(18, 2),
        nullable=False,
    )

    status = Column(
        String(30),
        nullable=False,
        default="SUCCESS",
    )

    description = Column(
        String(255),
        nullable=True,
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    account = relationship(
        "Account",
    )