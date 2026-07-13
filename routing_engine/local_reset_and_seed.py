import os
import sys
import asyncio
import random
from datetime import datetime, timedelta, timezone

# Add the routing_engine directory to sys.path so we can import 'app'
sys.path.append(os.path.join(os.path.dirname(__file__)))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.settings import TEST_DATABASE_URL, MOCK_PHARMACY_UUID
from app.models import Base, PharmacyNode, InventoryItem, StockRequest, TransactionLog, SystemAdmin

print("=========================================================")
print("WARNING: THIS SCRIPT WILL DROP AND RECREATE ALL TABLES.")
print("TARGETING LOCAL DATABASE URL:")
print(f"{TEST_DATABASE_URL}")
print("=========================================================")

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

def generate_location_point(city: str) -> str:
    # Approximate geographic coordinates
    cities = {
        "Mombasa": (39.66, -4.04),
        "Nairobi": (36.82, -1.29),
        "Kisumu": (34.75, -0.10),
        "Nakuru": (36.06, -0.30)
    }
    base_lon, base_lat = cities.get(city, (36.82, -1.29))
    
    # Introduce small random noise for spatial distribution
    lon = base_lon + random.uniform(-0.05, 0.05)
    lat = base_lat + random.uniform(-0.05, 0.05)
    return f"SRID=4326;POINT({lon} {lat})"

async def reset_and_seed():
    async with engine.begin() as conn:
        print("Dropping existing tables...")
        await conn.run_sync(Base.metadata.drop_all)
        print("Creating tables...")
        await conn.run_sync(Base.metadata.create_all)
    
    async with async_session() as session:
        # Seed the mock Admin for local bypass testing
        admin = SystemAdmin(
            admin_id="mock-admin",
            email="admin@local.test",
            role_level=5
        )
        session.add(admin)

        # 1. Pharmacies
        cities = ["Mombasa", "Nairobi", "Kisumu", "Nakuru"]
        pharmacies = []
        
        # The critical mock pharmacy for Mombasa
        mock_pharmacy = PharmacyNode(
            pharmacy_id=MOCK_PHARMACY_UUID,
            business_name="Local Mock Pharmacy (Mombasa)",
            license_number="LIC-MOCK-001",
            email="mock@pharmacy.test",
            phone_number="+254700000000",
            location=generate_location_point("Mombasa"),
            general_location="Mombasa, Mombasa",
            account_status="ACTIVE"
        )
        pharmacies.append(mock_pharmacy)
        
        for i in range(14):
            city = random.choice(cities)
            p = PharmacyNode(
                pharmacy_id=f"pharm-uuid-{i}",
                business_name=f"Pharmacy {i} {city}",
                license_number=f"LIC-{i}-{city}",
                email=f"pharm{i}@{city.lower()}.test",
                phone_number=f"+2547000000{i:02d}",
                location=generate_location_point(city),
                general_location=f"{city}, {city}",
                account_status="ACTIVE"
            )
            pharmacies.append(p)
        
        session.add_all(pharmacies)
        
        # 2. Inventory Items
        common_drugs = ["Paracetamol", "Amoxicillin", "Ibuprofen", "Cetirizine", "Omeprazole"]
        for p in pharmacies:
            for _ in range(random.randint(10, 20)):
                item = InventoryItem(
                    pharmacy_id=p.pharmacy_id,
                    drug_name=random.choice(common_drugs),
                    stock_quantity=random.randint(5, 50)
                )
                session.add(item)
                
        # 3. Outbreak Engine Data (Stock Requests)
        requests = []
        
        # Cluster 1: Mombasa (Fever/Chills Spike)
        for _ in range(8):
            req = StockRequest(
                pharmacy_id=mock_pharmacy.pharmacy_id,
                requested_drug="Paracetamol",
                drug_category="Antipyretic/Analgesic",
                required_quantity=random.randint(5, 20),
                shortage_reason="Fever/Chills Spike",
                request_status="PENDING",
                created_at=datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(hours=random.randint(1, 24))
            )
            requests.append(req)
            
        # Cluster 2: Kisumu (Waterborne Illness)
        kisumu_pharmacies = [p for p in pharmacies if "Kisumu" in p.general_location]
        if not kisumu_pharmacies: kisumu_pharmacies = [pharmacies[0]]
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

        # Cluster 3: Nairobi (Respiratory Spike)
        nairobi_pharmacies = [p for p in pharmacies if "Nairobi" in p.general_location]
        if not nairobi_pharmacies: nairobi_pharmacies = [pharmacies[0]]
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
                pharmacy_id=random.choice(pharmacies).pharmacy_id,
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

        print(f"Seeded {len(pharmacies)} pharmacies.")
        print(f"Seeded {len(requests)} stock requests (19 SIGNAL, 170 NOISE).")
        print(f"Seeded {len(logs)} transaction logs.")
        
        await session.commit()
        print("Database reset and seeded successfully!")

if __name__ == "__main__":
    asyncio.run(reset_and_seed())
