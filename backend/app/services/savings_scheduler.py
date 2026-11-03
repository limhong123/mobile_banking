import logging
from datetime import datetime, timezone
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from app.database import db

logger = logging.getLogger("savings_scheduler")
scheduler = AsyncIOScheduler()

async def process_matured_savings():
    """
    Scheduled job: runs daily at 00:05.
    Finds active deposits with maturity_date <= now and executes payout.
    """
    now = datetime.now(timezone.utc)
    logger.info(f"Running daily savings maturity job at {now.isoformat()}")

    cursor = db["savings"].find({
        "status": "active",
        "maturity_date": {"$lte": now},
    })
    matured_list = await cursor.to_list(length=1000)

    from app.routers.savings import payout_saving_deposit

    paid_count = 0
    for deposit in matured_list:
        try:
            dep_id = str(deposit["_id"])
            await payout_saving_deposit(dep_id)
            paid_count += 1
            logger.info(f"Successfully matured savings deposit {deposit.get('saving_id', dep_id)}")
        except Exception as e:
            logger.error(f"Failed to mature savings deposit {deposit.get('_id')}: {e}")

    logger.info(f"Maturity job completed. Paid out {paid_count} deposits.")
    return paid_count

def start_savings_scheduler():
    """
    Starts the APScheduler with daily job at 00:05.
    """
    if not scheduler.running:
        scheduler.add_job(
            process_matured_savings,
            CronTrigger(hour=0, minute=5),
            id="daily_savings_maturity_job",
            replace_existing=True,
        )
        scheduler.start()
        logger.info("Savings AsyncIOScheduler started: daily at 00:05")

def shutdown_savings_scheduler():
    """
    Gracefully shuts down the scheduler.
    """
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("Savings AsyncIOScheduler shut down")
