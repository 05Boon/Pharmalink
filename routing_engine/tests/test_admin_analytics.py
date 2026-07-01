import pytest
import datetime
from httpx import AsyncClient, ASGITransport

from app.database import get_db
from app.models import PharmacyNode, SystemAdmin, StockRequest
from app import schemas
from app import crud
from app.main import app


@pytest.mark.asyncio
async def test_outbreak_analytics_endpoint(db_session):
    # 1. Setup: Seed three pharmacies at distinct locations
    # Pharmacy A: Mombasa (-4.04, 39.68)
    profile_a = schemas.PharmacyProfileSync(
        business_name="Pharmacy A Business",
        license_number="PPB-RET-A",
        email="pharm_a@test.com",
        phone_number="070000000a",
        latitude=-4.04,
        longitude=39.68
    )
    await crud.create_pharmacy_node(db_session, "mock-pharmacy-a", profile_a)

    # Pharmacy B: Mombasa near A (-4.05, 39.69)
    profile_b = schemas.PharmacyProfileSync(
        business_name="Pharmacy B Business",
        license_number="PPB-RET-B",
        email="pharm_b@test.com",
        phone_number="070000000b",
        latitude=-4.05,
        longitude=39.69
    )
    await crud.create_pharmacy_node(db_session, "mock-pharmacy-b", profile_b)

    # Pharmacy C: Nairobi (-1.29, 36.82)
    profile_c = schemas.PharmacyProfileSync(
        business_name="Pharmacy C Business",
        license_number="PPB-RET-C",
        email="pharm_c@test.com",
        phone_number="070000000c",
        latitude=-1.29,
        longitude=36.82
    )
    await crud.create_pharmacy_node(db_session, "mock-pharmacy-c", profile_c)

    # 2. Seed an administrator into system_admins table
    admin = SystemAdmin(
        admin_id="mock-admin-uuid",
        email="admin@test.com",
        role_level=2
    )
    db_session.add(admin)
    await db_session.commit()

    # 3. Seed stock requests with custom creation dates to verify timeframe filtering
    now = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)

    # Aspirin: 2 requests (Pharmacy A created 2 days ago, Pharmacy B created 3 days ago)
    # Expected centroid: Latitude = (-4.04 + -4.05)/2 = -4.045, Longitude = (39.68 + 39.69)/2 = 39.685
    # Frequency: 2
    req_aspirin_1 = StockRequest(
        pharmacy_id="mock-pharmacy-a",
        requested_drug="Aspirin",
        required_quantity=10,
        created_at=now - datetime.timedelta(days=2)
    )
    req_aspirin_2 = StockRequest(
        pharmacy_id="mock-pharmacy-b",
        requested_drug="Aspirin",
        required_quantity=20,
        created_at=now - datetime.timedelta(days=3)
    )

    # Paracetamol: 2 requests within 7 days, 1 older than 7 days
    # (Pharmacy A created 1 day ago, Pharmacy C created 4 days ago)
    # Expected centroid: Latitude = (-4.04 + -1.29)/2 = -2.665, Longitude = (39.68 + 36.82)/2 = 38.25
    # Frequency (last 7 days): 2
    req_para_1 = StockRequest(
        pharmacy_id="mock-pharmacy-a",
        requested_drug="Paracetamol",
        required_quantity=5,
        created_at=now - datetime.timedelta(days=1)
    )
    req_para_2 = StockRequest(
        pharmacy_id="mock-pharmacy-c",
        requested_drug="Paracetamol",
        required_quantity=15,
        created_at=now - datetime.timedelta(days=4)
    )

    # Ibuprofen: 1 request older than 7 days (created 10 days ago)
    # Expected frequency (last 7 days): 0 (should not return)
    # Expected frequency (last 12 days): 1
    req_ibu_1 = StockRequest(
        pharmacy_id="mock-pharmacy-a",
        requested_drug="Ibuprofen",
        required_quantity=8,
        created_at=now - datetime.timedelta(days=10)
    )

    db_session.add_all([req_aspirin_1, req_aspirin_2, req_para_1, req_para_2, req_ibu_1])
    await db_session.commit()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # --- TEST 1: Unauthenticated request -> 401 Unauthorized ---
        response = await ac.get("/api/v1/admin/analytics/outbreaks")
        assert response.status_code == 401

        # --- TEST 2: Standard pharmacy attempt -> 403 Forbidden ---
        response = await ac.get(
            "/api/v1/admin/analytics/outbreaks",
            headers={"Authorization": "Bearer mock-pharmacy-a"}
        )
        assert response.status_code == 403

        # --- TEST 3: Admin request (default 7 days) -> 200 OK with correct values ---
        response = await ac.get(
            "/api/v1/admin/analytics/outbreaks",
            headers={"Authorization": "Bearer mock-admin-uuid"}
        )
        assert response.status_code == 200
        data = response.json()
        
        # Verify 2 active drugs (Aspirin, Paracetamol) returned; Ibuprofen excluded
        assert len(data) == 2
        
        aspirin_data = next(d for d in data if d["requested_drug"] == "Aspirin")
        assert aspirin_data["request_frequency"] == 2
        assert aspirin_data["centroid_latitude"] == pytest.approx(-4.045)
        assert aspirin_data["centroid_longitude"] == pytest.approx(39.685)

        para_data = next(d for d in data if d["requested_drug"] == "Paracetamol")
        assert para_data["request_frequency"] == 2
        assert para_data["centroid_latitude"] == pytest.approx(-2.665)
        assert para_data["centroid_longitude"] == pytest.approx(38.25)

        # --- TEST 4: Admin request with custom days parameter (e.g. days=12) ---
        response = await ac.get(
            "/api/v1/admin/analytics/outbreaks",
            params={"days": 12},
            headers={"Authorization": "Bearer mock-admin-uuid"}
        )
        assert response.status_code == 200
        data_12 = response.json()
        assert len(data_12) == 3
        
        ibu_data = next(d for d in data_12 if d["requested_drug"] == "Ibuprofen")
        assert ibu_data["request_frequency"] == 1
        assert ibu_data["centroid_latitude"] == pytest.approx(-4.04)
        assert ibu_data["centroid_longitude"] == pytest.approx(39.68)

        # --- TEST 5: Admin request with invalid negative days parameter -> 400 Bad Request ---
        response = await ac.get(
            "/api/v1/admin/analytics/outbreaks",
            params={"days": -1},
            headers={"Authorization": "Bearer mock-admin-uuid"}
        )
        assert response.status_code == 400
        assert "Days parameter must be a positive integer" in response.json()["detail"]
