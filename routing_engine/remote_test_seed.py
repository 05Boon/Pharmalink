import os
import sys
import asyncio
import random
from datetime import datetime, timedelta, timezone
from httpx import AsyncClient

# Add the routing_engine directory to sys.path so we can import 'app'
sys.path.append(os.path.join(os.path.dirname(__file__)))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.settings import (
    REMOTE_TEST_DB_URL, 
    REMOTE_SUPABASE_URL, 
    REMOTE_SUPABASE_ANON_KEY, 
    REMOTE_SUPABASE_SERVICE_ROLE_KEY
)
from app.models import Base, PharmacyNode, InventoryItem, StockRequest, TransactionLog, SystemAdmin

print("=========================================================")
print("WARNING: THIS SCRIPT WILL DROP AND RECREATE ALL TABLES ON")
print("THE REMOTE SUPABASE TEST DATABASE.")
print(f"URL: {REMOTE_TEST_DB_URL}")
print("=========================================================")

if not REMOTE_TEST_DB_URL or not REMOTE_SUPABASE_URL or not REMOTE_SUPABASE_SERVICE_ROLE_KEY:
    print("ERROR: Remote testing credentials are not fully configured in the environment.")
    print("Please set REMOTE_TEST_DB_URL, REMOTE_SUPABASE_URL, and REMOTE_SUPABASE_SERVICE_ROLE_KEY in .env")
    sys.exit(1)

engine = create_async_engine(REMOTE_TEST_DB_URL, echo=False)
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_or_create_user(client: AsyncClient, email: str, password: str, name: str) -> str:
    headers = {
        "apikey": REMOTE_SUPABASE_ANON_KEY or "",
        "Authorization": f"Bearer {REMOTE_SUPABASE_SERVICE_ROLE_KEY}",
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

    url = f"{REMOTE_SUPABASE_URL}/auth/v1/admin/users"
    resp = await client.post(url, json=payload, headers=headers)
    if resp.status_code in [200, 201]:
        data = resp.json()
        print(f"Registered brand new Supabase Auth account: {email}")
        return data["id"]
    elif resp.status_code in [400, 422]:
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

def generate_location_point(city: str) -> str:
    cities = {
        "Mombasa": (39.66, -4.04),
        "Nairobi": (36.82, -1.29),
        "Kisumu": (34.75, -0.10),
        "Nakuru": (36.06, -0.30)
    }
    base_lon, base_lat = cities.get(city, (36.82, -1.29))
    lon = base_lon + random.uniform(-0.05, 0.05)
    lat = base_lat + random.uniform(-0.05, 0.05)
    return f"SRID=4326;POINT({lon} {lat})"

async def reset_and_seed():
    print("Initializing Seeder connection...")
    async with AsyncClient() as client:
        # 1. Register Admin
        admin_uuid = await get_or_create_user(
            client,
            "admin@pharmalink.dev",
            "adminpass123",
            "System Administrator",
        )

        # 2. Register Pharmacies in Auth
        cities = ["Mombasa", "Nairobi", "Kisumu", "Nakuru"]
        pharmacy_auth_profiles = []
        
        for i in range(15):
            city = random.choice(cities)
            # Ensure at least one Mombasa pharmacy for the cluster
            if i == 0:
                city = "Mombasa"
                
            email = f"pharm{i}@{city.lower()}.test"
            name = f"Pharmacy {i} {city}"
            
            uuid = await get_or_create_user(
                client,
                email,
                "testpass123",
                name,
            )
            pharmacy_auth_profiles.append({
                "uuid": uuid,
                "city": city,
                "email": email,
                "name": name,
                "license": f"LIC-{i}-{city}",
                "phone": f"+2547000000{i:02d}"
            })

    # Now do database seeding
    from sqlalchemy import text
    async with engine.begin() as conn:
        print("Ensuring PostGIS extension is enabled...")
        await conn.execute(text('CREATE EXTENSION IF NOT EXISTS postgis;'))
        
        print("Dropping existing tables...")
        await conn.run_sync(Base.metadata.drop_all)
        print("Creating tables...")
        await conn.run_sync(Base.metadata.create_all)
        
    async with async_session() as session:
        admin = SystemAdmin(
            admin_id=admin_uuid,
            email="admin@pharmalink.dev",
            role_level=5
        )
        session.add(admin)
        
        # 1. Pharmacies
        db_pharmacies = []
        for profile in pharmacy_auth_profiles:
            p = PharmacyNode(
                pharmacy_id=profile["uuid"],
                business_name=profile["name"],
                license_number=profile["license"],
                email=profile["email"],
                phone_number=profile["phone"],
                location=generate_location_point(profile["city"]),
                general_location=f"{profile['city']}, {profile['city']}",
                account_status="ACTIVE"
            )
            db_pharmacies.append(p)
        session.add_all(db_pharmacies)
        
        # 2. Inventory Items
        common_drugs = ["Paracetamol", "Amoxicillin", "Ibuprofen", "Cetirizine", "Omeprazole"]
        for p in db_pharmacies:
            for _ in range(random.randint(10, 20)):
                item = InventoryItem(
                    pharmacy_id=p.pharmacy_id,
                    drug_name=random.choice(common_drugs),
                    stock_quantity=random.randint(5, 50)
                )
                session.add(item)
                
        # 3. Outbreak Engine Data (Stock Requests)
        requests = []
        
        # Extract specific pharmacies by city
        mombasa_pharmacies = [p for p in db_pharmacies if "Mombasa" in p.general_location]
        kisumu_pharmacies = [p for p in db_pharmacies if "Kisumu" in p.general_location]
        nairobi_pharmacies = [p for p in db_pharmacies if "Nairobi" in p.general_location]
        
        # Fallbacks just in case
        if not kisumu_pharmacies: kisumu_pharmacies = [db_pharmacies[0]]
        if not nairobi_pharmacies: nairobi_pharmacies = [db_pharmacies[0]]
        
        # Cluster 1: Mombasa
        for _ in range(8):
            req = StockRequest(
                pharmacy_id=random.choice(mombasa_pharmacies).pharmacy_id,
                requested_drug="Paracetamol",
                drug_category="Antipyretic/Analgesic",
                required_quantity=random.randint(5, 20),
                shortage_reason="Fever/Chills Spike",
                request_status="PENDING",
                created_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(hours=random.randint(1, 24))
            )
            requests.append(req)
            
        # Cluster 2: Kisumu
        for _ in range(6):
            req = StockRequest(
                pharmacy_id=random.choice(kisumu_pharmacies).pharmacy_id,
                requested_drug="Amoxicillin",
                drug_category="Antibiotic",
                required_quantity=random.randint(10, 30),
                shortage_reason="Waterborne Illness",
                request_status="PENDING",
                created_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(hours=random.randint(1, 24))
            )
            requests.append(req)

        # Cluster 3: Nairobi
        for _ in range(5):
            req = StockRequest(
                pharmacy_id=random.choice(nairobi_pharmacies).pharmacy_id,
                requested_drug="Cetirizine",
                drug_category="Antihistamine",
                required_quantity=random.randint(5, 15),
                shortage_reason="Respiratory Spike",
                request_status="PENDING",
                created_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(hours=random.randint(1, 24))
            )
            requests.append(req)
            
        # Noise
        for _ in range(170):
            status = random.choice(["PENDING", "COMPLETED"])
            req = StockRequest(
                pharmacy_id=random.choice(db_pharmacies).pharmacy_id,
                requested_drug=random.choice(common_drugs),
                drug_category="General",
                required_quantity=random.randint(1, 10),
                shortage_reason="Routine Restock",
                request_status=status,
                created_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(days=random.randint(1, 5))
            )
            requests.append(req)
            
        session.add_all(requests)
        await session.flush()
        
        # 4. Transaction Logs
        logs = []
        for req in requests:
            if req.request_status == "COMPLETED" or random.random() < 0.2:
                log = TransactionLog(
                    request_id=req.request_id,
                    drug_category=req.drug_category,
                    final_outcome="FULFILLED_BY_NEIGHBOR" if req.request_status == "COMPLETED" else "EXPIRED",
                    resolved_at=req.created_at + timedelta(hours=random.randint(1, 12))
                )
                logs.append(log)
        session.add_all(logs)
        
        await session.commit()
        print(f"Seeded {len(db_pharmacies)} remote auth pharmacies.")
        print(f"Seeded {len(requests)} stock requests (19 SIGNAL, 170 NOISE).")
        print(f"Seeded {len(logs)} transaction logs.")
        print("Remote database reset and seeded successfully!")

if __name__ == "__main__":
    asyncio.run(reset_and_seed())
