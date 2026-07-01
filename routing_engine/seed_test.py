import asyncio
from app.database import AsyncSessionLocal
from app.models import PharmacyNode
from sqlalchemy.future import select

async def test_database_insert():
    print("Testing database connection and model insertion...")
    
    async with AsyncSessionLocal() as db:
        try:
            # 1. Create a dummy pharmacy in Nyali (Mombasa)
            # Longitude comes first in PostGIS POINT(lon lat)
            nyali_pharmacy = PharmacyNode(
                pharmacy_id="test-pharmacy-uuid-2234", 
                business_name="Nyali Central Pharmacy",
                license_number="PPB-TEST-001",
                email="admin@nyalicentral.com",
                phone_number="+254700000000",
                location="POINT(-4.046956 39.698434)"  # Nyali, Mombasa coordinates
            )
            
            # 2. Add and commit to the database
            db.add(nyali_pharmacy)
            await db.commit()
            
            # 3. Retrieve it to prove it saved correctly
            result = await db.execute(
                select(PharmacyNode).where(PharmacyNode.license_number == "PPB-TEST-001")
            )
            saved_pharmacy = result.scalar_one_or_none()
            
            if saved_pharmacy:
                print(f"SUCCESS! Pharmacy '{saved_pharmacy.business_name}' saved with UUID: {saved_pharmacy.pharmacy_id}")
            else:
                print("FAILED: Could not retrieve the inserted pharmacy.")
                
        except Exception as e:
            await db.rollback()
            print(f"ERROR: {e}")

if __name__ == "__main__":
    asyncio.run(test_database_insert())
