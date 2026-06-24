import pytest
import pytest_asyncio
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

from database import DATABASE_URL
from models import Base, PharmacyNode, InventoryItem
import crud

# Fixture to set up test engine and database tables
@pytest_asyncio.fixture
async def test_engine():
    engine = create_async_engine(DATABASE_URL, echo=False, future=True)
    async with engine.begin() as conn:
        # Create all tables (will create them if they do not exist)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

# Fixture to yield a database session and clean up created test records after each test
@pytest_asyncio.fixture
async def db_session(test_engine):
    AsyncSessionLocal = sessionmaker(
        bind=test_engine, 
        class_=AsyncSession, 
        expire_on_commit=False
    )
    async with AsyncSessionLocal() as session:
        yield session
        await session.rollback()

@pytest.mark.asyncio
async def test_spatial_dwithin_filtering(db_session: AsyncSession):
    # 0. Hermetic database cleanup - remove pre-existing items/nodes from previous runs
    await db_session.execute(text("DELETE FROM inventory_items WHERE pharmacy_id LIKE 'spatial-node-%'"))
    await db_session.execute(text("DELETE FROM pharmacy_nodes WHERE pharmacy_id LIKE 'spatial-node-%'"))
    await db_session.commit()

    # 1. Setup - Create 3 pharmacy nodes in Mombasa (WGS 84 SRID 4326)
    # Origin location reference: Nyali Central - POINT(39.698434 -4.046956)
    
    # Node 1: Close Pharmacy (~110m away from origin)
    pharmacy_close = PharmacyNode(
        pharmacy_id="spatial-node-close",
        business_name="Close Nyali Pharmacy",
        license_number="PPB-SPATIAL-1",
        email="close@nyali.com",
        phone_number="+254700000010",
        location="POINT(39.698000 -4.046000)"
    )
    
    # Node 2: Medium Distance Pharmacy (~1.4km away from origin)
    pharmacy_medium = PharmacyNode(
        pharmacy_id="spatial-node-medium",
        business_name="Medium Mombasa Pharmacy",
        license_number="PPB-SPATIAL-2",
        email="medium@mombasa.com",
        phone_number="+254700000020",
        location="POINT(39.710000 -4.055000)"
    )
    
    # Node 3: Far Distance Pharmacy (~5.6km away from origin)
    pharmacy_far = PharmacyNode(
        pharmacy_id="spatial-node-far",
        business_name="Far Kilifi Pharmacy",
        license_number="PPB-SPATIAL-3",
        email="far@kilifi.com",
        phone_number="+254700000030",
        location="POINT(39.660000 -4.080000)"
    )
    
    # Merge/Add nodes to database
    await db_session.merge(pharmacy_close)
    await db_session.merge(pharmacy_medium)
    await db_session.merge(pharmacy_far)
    await db_session.commit()

    # 2. Seed stock for "Amoxicillin 500mg" at these nodes using explicit primary keys
    inventory_close = InventoryItem(
        item_id="spatial-item-close",
        pharmacy_id="spatial-node-close",
        drug_name="Amoxicillin 500mg",
        drug_category="Antibiotics",
        stock_quantity=50
    )
    inventory_medium = InventoryItem(
        item_id="spatial-item-medium",
        pharmacy_id="spatial-node-medium",
        drug_name="Amoxicillin 500mg",
        drug_category="Antibiotics",
        stock_quantity=50
    )
    inventory_far = InventoryItem(
        item_id="spatial-item-far",
        pharmacy_id="spatial-node-far",
        drug_name="Amoxicillin 500mg",
        drug_category="Antibiotics",
        stock_quantity=100
    )
    
    await db_session.merge(inventory_close)
    await db_session.merge(inventory_medium)
    await db_session.merge(inventory_far)
    await db_session.commit()

    # Define origin coordinate (Nyali Central reference coordinate)
    origin_ewkt = "SRID=4326;POINT(39.698434 -4.046956)"

    # --- Test Case 1: Search within 1000 meters for 10 units ---
    # Expected: Only 'spatial-node-close' should match.
    results_1000m = await crud.find_neighboring_pharmacies(
        db_session, origin_ewkt, radius_meters=1000, drug_name="Amoxicillin 500mg", required_quantity=10
    )
    print("\n🔍 [Test Case 1 (1000m, Qty 10)] Matched Pharmacies:")
    for p in results_1000m:
        print(f"   - {p.business_name} ({p.pharmacy_id})")
    assert len(results_1000m) == 1
    assert results_1000m[0].pharmacy_id == "spatial-node-close"

    # --- Test Case 2: Search within 2500 meters for 10 units ---
    # Expected: Both 'spatial-node-close' and 'spatial-node-medium' should match.
    results_2500m = await crud.find_neighboring_pharmacies(
        db_session, origin_ewkt, radius_meters=2500, drug_name="Amoxicillin 500mg", required_quantity=10
    )
    print("\n🔍 [Test Case 2 (2500m, Qty 10)] Matched Pharmacies:")
    for p in results_2500m:
        print(f"   - {p.business_name} ({p.pharmacy_id})")
    assert len(results_2500m) == 2
    pharmacy_ids = {p.pharmacy_id for p in results_2500m}
    assert "spatial-node-close" in pharmacy_ids
    assert "spatial-node-medium" in pharmacy_ids

    # --- Test Case 3: Search within 2500 meters for 60 units ---
    # Expected: No pharmacies should match because close/medium only have 50 units.
    results_high_qty = await crud.find_neighboring_pharmacies(
        db_session, origin_ewkt, radius_meters=2500, drug_name="Amoxicillin 500mg", required_quantity=60
    )
    print("\n🔍 [Test Case 3 (2500m, Qty 60)] Matched Pharmacies:")
    for p in results_high_qty:
        print(f"   - {p.business_name} ({p.pharmacy_id})")
    if not results_high_qty:
        print("   - No pharmacies met the stock requirements (qty >= 60).")
    assert len(results_high_qty) == 0

    # --- Test Case 4: Search within 7000 meters for 60 units ---
    # Expected: Only 'spatial-node-far' should match (has 100 units and is within 7km).
    results_far_match = await crud.find_neighboring_pharmacies(
        db_session, origin_ewkt, radius_meters=7000, drug_name="Amoxicillin 500mg", required_quantity=60
    )
    print("\n🔍 [Test Case 4 (7000m, Qty 60)] Matched Pharmacies:")
    for p in results_far_match:
        print(f"   - {p.business_name} ({p.pharmacy_id})")
    assert len(results_far_match) == 1
    assert results_far_match[0].pharmacy_id == "spatial-node-far"
    print("")
