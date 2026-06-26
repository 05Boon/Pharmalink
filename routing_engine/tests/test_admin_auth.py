import pytest
import pytest_asyncio
from httpx2 import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from database import DATABASE_URL, get_db
from models import Base, PharmacyNode, SystemAdmin
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
async def test_admin_auth_and_status_toggle(db_session):
    # 1. Setup: Seed a pharmacy node
    profile_a = schemas.PharmacyProfileSync(
        business_name="Pharmacy A Business",
        license_number="PPB-RET-A",
        email="pharm_a@test.com",
        phone_number="070000000a",
        latitude=-4.04,
        longitude=39.68
    )
    await crud.create_pharmacy_node(db_session, "mock-pharmacy-a", profile_a)

    # 2. Seed an administrator into system_admins table
    admin = SystemAdmin(
        admin_id="mock-admin-uuid",
        email="admin@test.com",
        role_level=2
    )
    db_session.add(admin)
    await db_session.commit()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # --- TEST 1: Standard pharmacy attempts status change -> 403 Forbidden ---
        response = await ac.patch(
            "/api/admin/pharmacies/mock-pharmacy-a/status",
            json={"account_status": "SUSPENDED"},
            headers={"Authorization": "Bearer mock-pharmacy-a"}
        )
        assert response.status_code == 403
        assert "Admin privilege required" in response.json()["detail"]

        # --- TEST 2: Unauthenticated request -> 401 Unauthorized ---
        response = await ac.patch(
            "/api/admin/pharmacies/mock-pharmacy-a/status",
            json={"account_status": "SUSPENDED"}
        )
        assert response.status_code == 401

        # --- TEST 3: Admin changes status -> 200 OK and returns correct response ---
        response = await ac.patch(
            "/api/admin/pharmacies/mock-pharmacy-a/status",
            json={"account_status": "SUSPENDED"},
            headers={"Authorization": "Bearer mock-admin-uuid"}
        )
        assert response.status_code == 200
        
        data = response.json()
        assert data["pharmacy_id"] == "mock-pharmacy-a"
        assert data["account_status"] == "SUSPENDED"
        assert data["latitude"] == pytest.approx(-4.04)
        assert data["longitude"] == pytest.approx(39.68)

        # Verify DB value is updated
        updated_node = await crud.get_pharmacy_node(db_session, "mock-pharmacy-a")
        assert updated_node is not None
        assert updated_node.account_status == "SUSPENDED"

        # --- TEST 4: Admin attempts status update on non-existent pharmacy -> 404 Not Found ---
        response = await ac.patch(
            "/api/admin/pharmacies/non-existent-pharmacy/status",
            json={"account_status": "ACTIVE"},
            headers={"Authorization": "Bearer mock-admin-uuid"}
        )
        assert response.status_code == 404
        assert "Pharmacy node not found" in response.json()["detail"]
