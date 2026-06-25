import pytest
import pytest_asyncio
from httpx2 import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from database import DATABASE_URL, get_db
from models import Base, PharmacyNode, StockRequest, AlertNotification
import schemas
import crud
from main import app

@pytest_asyncio.fixture
async def test_engine():
    engine = create_async_engine(DATABASE_URL, echo=False, future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()

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

@pytest.fixture(autouse=True)
def override_db_dependency(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    yield
    app.dependency_overrides.pop(get_db, None)

@pytest.mark.asyncio
async def test_retrieval_endpoints(db_session):
    # 1. Setup: Seed Pharmacy A and Pharmacy B
    profile_a = schemas.PharmacyProfileSync(
        business_name="Pharmacy A Business",
        license_number="PPB-RET-A",
        email="pharm_a@test.com",
        phone_number="070000000a",
        latitude=-4.04,
        longitude=39.68
    )
    profile_b = schemas.PharmacyProfileSync(
        business_name="Pharmacy B Business",
        license_number="PPB-RET-B",
        email="pharm_b@test.com",
        phone_number="070000000b",
        latitude=-4.05,
        longitude=39.69
    )
    await crud.create_pharmacy_node(db_session, "mock-pharmacy-a", profile_a)
    await crud.create_pharmacy_node(db_session, "mock-pharmacy-b", profile_b)
    
    # 2. Seed requests
    # Request A1: Active (PENDING)
    req_a1 = schemas.StockRequestCreate(
        pharmacy_id="mock-pharmacy-a",
        requested_drug="Aspirin 100mg",
        required_quantity=10,
        search_radius_meters=1500
    )
    db_req_a1 = await crud.create_stock_request(db_session, req_a1)
    
    # Request A2: Resolved (FULFILLED)
    req_a2 = schemas.StockRequestCreate(
        pharmacy_id="mock-pharmacy-a",
        requested_drug="Panadol 500mg",
        required_quantity=20,
        search_radius_meters=2000
    )
    db_req_a2 = await crud.create_stock_request(db_session, req_a2)
    await crud.update_stock_request_status(db_session, db_req_a2.request_id, "FULFILLED")
    
    # Request B1: Active (PENDING) by Pharmacy B
    req_b1 = schemas.StockRequestCreate(
        pharmacy_id="mock-pharmacy-b",
        requested_drug="Amoxicillin 500mg",
        required_quantity=5,
        search_radius_meters=1000
    )
    db_req_b1 = await crud.create_stock_request(db_session, req_b1)
    
    # 3. Seed alert notifications
    # Alert A1: targeted at Pharmacy A, unread, linked to B's request
    alert_a1 = schemas.AlertNotificationCreate(
        request_id=db_req_b1.request_id,
        receiving_pharmacy_id="mock-pharmacy-a",
        alert_status="UNREAD"
    )
    await crud.create_alert_notification(db_session, alert_a1)
    
    # Alert A2: targeted at Pharmacy A, already READ, linked to B's request
    alert_a2 = schemas.AlertNotificationCreate(
        request_id=db_req_b1.request_id,
        receiving_pharmacy_id="mock-pharmacy-a",
        alert_status="READ"
    )
    db_alert_a2 = await crud.create_alert_notification(db_session, alert_a2)
    await crud.update_alert_status(db_session, db_alert_a2.alert_id, "READ")
    
    # Alert B1: targeted at Pharmacy B, unread, linked to A's request
    alert_b1 = schemas.AlertNotificationCreate(
        request_id=db_req_a1.request_id,
        receiving_pharmacy_id="mock-pharmacy-b",
        alert_status="UNREAD"
    )
    await crud.create_alert_notification(db_session, alert_b1)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # --- TEST 1: GET /broadcasts/active-requests (as Pharmacy A) ---
        response = await ac.get(
            "/broadcasts/active-requests",
            headers={"Authorization": "Bearer mock-pharmacy-a"}
        )
        assert response.status_code == 200
        active_requests = response.json()
        
        # Verify active requests count and data isolation
        assert len(active_requests) == 1
        assert active_requests[0]["request_id"] == db_req_a1.request_id
        assert active_requests[0]["requested_drug"] == "Aspirin 100mg"
        assert active_requests[0]["request_status"] == "PENDING"
        
        # --- TEST 2: GET /broadcasts/alerts/unread (as Pharmacy A) ---
        response = await ac.get(
            "/broadcasts/alerts/unread",
            headers={"Authorization": "Bearer mock-pharmacy-a"}
        )
        assert response.status_code == 200
        unread_alerts = response.json()
        
        # Verify unread alerts count and eager relationship loading details
        assert len(unread_alerts) == 1
        alert = unread_alerts[0]
        assert alert["receiving_pharmacy_id"] == "mock-pharmacy-a"
        assert alert["alert_status"] == "UNREAD"
        assert alert["request_id"] == db_req_b1.request_id
        
        # Verify eager loaded request fields
        assert alert["request"]["requested_drug"] == "Amoxicillin 500mg"
        assert alert["request"]["required_quantity"] == 5
        
        # Verify eager loaded requesting pharmacy fields (Pharmacy B details)
        assert alert["request"]["pharmacy"]["pharmacy_id"] == "mock-pharmacy-b"
        assert alert["request"]["pharmacy"]["business_name"] == "Pharmacy B Business"
        assert alert["request"]["pharmacy"]["phone_number"] == "070000000b"
        
        # --- TEST 3: GET /broadcasts/alerts/unread (as Pharmacy B) ---
        response = await ac.get(
            "/broadcasts/alerts/unread",
            headers={"Authorization": "Bearer mock-pharmacy-b"}
        )
        assert response.status_code == 200
        unread_alerts_b = response.json()
        
        # Verify Pharmacy B unread alert and its eager loaded requesting pharmacy (Pharmacy A)
        assert len(unread_alerts_b) == 1
        alert_b = unread_alerts_b[0]
        assert alert_b["receiving_pharmacy_id"] == "mock-pharmacy-b"
        assert alert_b["request"]["pharmacy"]["pharmacy_id"] == "mock-pharmacy-a"
        assert alert_b["request"]["pharmacy"]["business_name"] == "Pharmacy A Business"
