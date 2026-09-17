import asyncio
from app.database import db
from app.utils.security import hash_pin

ADMIN_PHONE = "023951111"
ADMIN_PIN = "999999"  # ប្តូរជា PIN សម្ងាត់ផ្ទាល់ខ្លួន

async def create_admin():
    users_collection = db["users"]

    existing_admin = await users_collection.find_one({"role": "admin"})
    if existing_admin:
        print(f"Admin already exists: {existing_admin['phone_number']}. Aborting.")
        return

    existing_user = await users_collection.find_one({"phone_number": ADMIN_PHONE})
    if existing_user:
        print("Phone number already used by another account. Choose a different one.")
        return

    admin_user = {
        "first_name": "Admin",
        "last_name": "KhemPay",
        "phone_number": ADMIN_PHONE,
        "pin": hash_pin(ADMIN_PIN),
        "is_verified": True,
        "kyc_status": "approved",
        "role": "admin",
    }

    await users_collection.insert_one(admin_user)
    print(f"Admin created successfully: {ADMIN_PHONE}")

if __name__ == "__main__":
    asyncio.run(create_admin())