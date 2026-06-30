import asyncio
import datetime
from httpx import AsyncClient

from database import AsyncSessionLocal
from models import PharmacyNode, InventoryItem, SystemAdmin, StockRequest, AlertNotification
from settings import SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
from sqlalchemy.future import select

# Seed data for Nairobi test pharmacies
PHARMACIES = [
    {
        "name": "CBD Test Pharmacy",
        "email": "cbd.pharmacy@pharmalinktest.dev",
        "password": "testpass123",
        "license_number": "PPB-10001",
        "phone_number": "0700100001",
        "latitude": -1.2841,
        "longitude": 36.8233,
        "neighborhood": "CBD",
    },
    {
        "name": "Westlands Test Pharmacy",
        "email": "westlands.pharmacy@pharmalinktest.dev",
        "password": "testpass123",
        "license_number": "PPB-10002",
        "phone_number": "0700100002",
        "latitude": -1.2675,
        "longitude": 36.8108,
        "neighborhood": "Westlands",
    },
    {
        "name": "Kilimani Test Pharmacy",
        "email": "kilimani.pharmacy@pharmalinktest.dev",
        "password": "testpass123",
        "license_number": "PPB-10003",
        "phone_number": "0700100003",
        "latitude": -1.2906,
        "longitude": 36.7820,
        "neighborhood": "Kilimani",
    },
    {
        "name": "Eastleigh Test Pharmacy",
        "email": "eastleigh.pharmacy@pharmalinktest.dev",
        "password": "testpass123",
        "license_number": "PPB-10004",
        "phone_number": "0700100004",
        "latitude": -1.2784,
        "longitude": 36.8470,
        "neighborhood": "Eastleigh",
    },
    {
        "name": "Karen Test Pharmacy",
        "email": "karen.pharmacy@pharmalinktest.dev",
        "password": "testpass123",
        "license_number": "PPB-10005",
        "phone_number": "0700100005",
        "latitude": -1.3192,
        "longitude": 36.7076,
        "neighborhood": "Karen",
    },
    {
        "name": "South B Test Pharmacy",
        "email": "southb.pharmacy@pharmalinktest.dev",
        "password": "testpass123",
        "license_number": "PPB-10006",
        "phone_number": "0700100006",
        "latitude": -1.3107,
        "longitude": 36.8345,
        "neighborhood": "South B",
    },
]

DRUGS = [
    {"name": "Paracetamol 500mg", "category": "Analgesics", "quantity": 120},
    {"name": "Aspirin 75mg", "category": "Analgesics", "quantity": 80},
    {"name": "Ibuprofen 400mg", "category": "Analgesics", "quantity": 95},
    {"name": "Amoxicillin 500mg", "category": "Antibiotics", "quantity": 60},
    {"name": "Metformin 500mg", "category": "Antidiabetics", "quantity": 110},
    {"name": "Atorvastatin 20mg", "category": "Cardiovascular", "quantity": 50},
    {"name": "Omeprazole 20mg", "category": "Gastrointestinal", "quantity": 90},
    {"name": "Cetirizine 10mg", "category": "Antihistamines", "quantity": 130},
    {"name": "Salbutamol Inhaler", "category": "Respiratory", "quantity": 40},
    {"name": "Losartan 50mg", "category": "Cardiovascular", "quantity": 70},
]


async def get_or_create_user(client: AsyncClient, email: str, password: str, name: str) -> str:
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "email": email,
        "password": password,
        "email_confirm": True,
        "user_metadata": {
            "business_name": name,
        },
    }

    url = f"{SUPABASE_URL}/auth/v1/admin/users"
    resp = await client.post(url, json=payload, headers=headers)
    if resp.status_code == 201:
        data = resp.json()
        print(f"Registered brand new Supabase Auth account: {email}")
        return data["id"]
    elif resp.status_code in [400, 422]:
        # Attempt to search list to retrieve uuid for existing mock user
        search_resp = await client.get(url, headers=headers)
        if search_resp.status_code == 200:
            users = search_resp.json().get("users", [])
            for u in users:
                if u.get("email") == email:
                    print(f"Reusing existing Supabase Auth account: {email} -> {u['id']}")
                    return u["id"]
        raise RuntimeError(f"User {email} already exists but list call failed: {resp.text}")
    else:
        raise RuntimeError(f"Failed GoTrue connection: {resp.status_code} - {resp.text}")


async def seed():
    print("Initializing Seeder connection...")
    async with AsyncClient() as client:
        # 1. Register or find admin account
        admin_uuid = await get_or_create_user(
            client,
            "admin@pharmalink.dev",
            "adminpass123",
            "System Administrator",
        )

        async with AsyncSessionLocal() as db:
            # Sync Administrator
            existing_admin = await db.execute(
                select(SystemAdmin).where(SystemAdmin.admin_id == admin_uuid)
            )
            if not existing_admin.scalar_one_or_none():
                admin = SystemAdmin(
                    admin_id=admin_uuid,
                    email="admin@pharmalink.dev",
                    role_level=2,
                )
                db.add(admin)
                await db.commit()
                print("Seeded SystemAdmin profile record successfully.")

            # 2. Sync Pharmacies
            pharmacy_uuids = {}
            for p in PHARMACIES:
                uuid = await get_or_create_user(
                    client,
                    p["email"],
                    p["password"],
                    p["name"],
                )
                pharmacy_uuids[p["name"]] = uuid

                # Check and sync database profile
                existing_pharm = await db.execute(
                    select(PharmacyNode).where(PharmacyNode.pharmacy_id == uuid)
                )
                if not existing_pharm.scalar_one_or_none():
                    node = PharmacyNode(
                        pharmacy_id=uuid,
                        business_name=p["name"],
                        license_number=p["license_number"],
                        email=p["email"],
                        phone_number=p["phone_number"],
                        location=f"POINT({p['longitude']} {p['latitude']})",
                        account_status="approved",
                    )
                    db.add(node)
                    await db.commit()
                    print(f"Created PharmacyNode profile: {p['name']} ({p['neighborhood']})")

                # 3. Seed Inventory items
                # Clean up existing inventory items for this pharmacy to avoid duplications
                from sqlalchemy import delete
                await db.execute(
                    delete(InventoryItem).where(InventoryItem.pharmacy_id == uuid)
                )
                await db.commit()

                # Add standard items
                for d in DRUGS:
                    item = InventoryItem(
                        pharmacy_id=uuid,
                        drug_name=d["name"],
                        drug_category=d["category"],
                        stock_quantity=d["quantity"],
                    )
                    db.add(item)
                await db.commit()
                print(f"Populated inventory stock records for: {p['name']}")

            # 4. Seed Outbreak Mock Data (Stock Requests & Alerts)
            # Clean existing stock requests and alerts
            from sqlalchemy import text
            await db.execute(text("TRUNCATE TABLE alert_notifications CASCADE;"))
            await db.execute(text("TRUNCATE TABLE stock_requests CASCADE;"))
            await db.commit()

            now = datetime.datetime.now()

            # Seed a few stock requests to simulate search queries & outbreaks
            # Request 1: Westlands Pharmacy requests Paracetamol (3 days ago)
            req_para_west = StockRequest(
                pharmacy_id=pharmacy_uuids["Westlands Test Pharmacy"],
                requested_drug="Paracetamol 500mg",
                required_quantity=50,
                created_at=now - datetime.timedelta(days=3),
            )
            # Request 2: Kilimani Pharmacy requests Paracetamol (2 days ago)
            req_para_kili = StockRequest(
                pharmacy_id=pharmacy_uuids["Kilimani Test Pharmacy"],
                requested_drug="Paracetamol 500mg",
                required_quantity=30,
                created_at=now - datetime.timedelta(days=2),
            )
            # Request 3: CBD Pharmacy requests Amoxicillin (1 day ago)
            req_amox_cbd = StockRequest(
                pharmacy_id=pharmacy_uuids["CBD Test Pharmacy"],
                requested_drug="Amoxicillin 500mg",
                required_quantity=20,
                created_at=now - datetime.timedelta(days=1),
            )
            db.add_all([req_para_west, req_para_kili, req_amox_cbd])
            await db.commit()

            # Retrieve and seed alert notifications
            # Let's seed a pending alert for Westlands and Kilimani for testing incoming UI alerts
            alert_1 = AlertNotification(
                request_id=req_para_west.request_id,
                target_pharmacy_id=pharmacy_uuids["Kilimani Test Pharmacy"],
                distance_meters=1800.0,
                status="pending",
                created_at=now - datetime.timedelta(days=3),
            )
            alert_2 = AlertNotification(
                request_id=req_para_kili.request_id,
                target_pharmacy_id=pharmacy_uuids["Westlands Test Pharmacy"],
                distance_meters=1800.0,
                status="pending",
                created_at=now - datetime.timedelta(days=2),
            )
            db.add_all([alert_1, alert_2])
            await db.commit()
            print("Successfully populated mock stock requests and pending alert notifications.")

    print("\nDatabase Seeding completed successfully! 🎉")
    print("Credentials to test logging in:")
    print("---------------------------------------------")
    print("Admin:  admin@pharmalink.dev / adminpass123")
    for p in PHARMACIES[:3]:
        print(f"Pharmacy: {p['email']} / {p['password']}")


if __name__ == "__main__":
    asyncio.run(seed())
