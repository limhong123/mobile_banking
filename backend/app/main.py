from pathlib import Path
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.routers import (
    accounts,
    admin,
    agent,
    auth,
    admin_wallet,
    deposits,
    kyc,
    transfers,
    notifications,
    transactions,
    cash_transfers,
    profile,
    savings,
)
from app.services.firebase_notification_service import (
    initialize_firebase,
)
from app.services.savings_scheduler import (
    start_savings_scheduler,
    shutdown_savings_scheduler,
)

BASE_DIR = (
    Path(__file__)
    .resolve()
    .parent
    .parent
)

UPLOAD_DIR = (
    BASE_DIR / "uploads"
)

UPLOAD_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    initialize_firebase()
    start_savings_scheduler()
    yield
    # Shutdown
    shutdown_savings_scheduler()


app = FastAPI(
    title="KhmerPay Mobile Banking API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,

    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],

    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==========================================
# ROUTERS
# ==========================================

# Auth
app.include_router(
    auth.router
)

# KYC
app.include_router(
    kyc.router
)

# Admin users / agents
app.include_router(
    admin.router
)

# Admin System Wallet
app.include_router(
    admin_wallet.router
)

# Agent
app.include_router(
    agent.router
)

# Customer deposit balance/history
app.include_router(
    deposits.router
)
app.include_router(
    notifications.router
)
app.include_router(
    accounts.router
)

app.include_router(
    transfers.router
)
app.include_router(
    transactions.router
)
app.include_router(
    cash_transfers.router
)
app.include_router(
    profile.router
)
app.include_router(
    savings.router
)
# ==========================================
# STATIC FILES
# ==========================================

app.mount(
    "/uploads",

    StaticFiles(
        directory=str(
            UPLOAD_DIR
        ),
    ),

    name="uploads",
)


# ==========================================
# ROOT
# ==========================================

@app.get("/")
async def root():
    return {
        "success": True,
        "message": (
            "KhmerPay Mobile Banking API "
            "is running"
        ),
    }


# ==========================================
# HEALTH
# ==========================================

@app.get("/health")
async def health_check():
    return {
        "success": True,
        "status": "healthy",
    }