import pytest
from httpx import AsyncClient, ASGITransport

from app.database import get_db
from app import crud
from app import schemas
from app.main import app


@pytest.mark.asyncio
async def test_sync_profile_success(db_session):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        headers = {"Authorization": "Bearer mock-auth-sync-uuid-1"}
        payload = {
            "business_name": "Sync test pharmacy",
            "license_number": "PPB-SYNC-999",
            "email": "sync@test.com",
            "phone_number": "0799999999",
            "latitude": -4.046,
            "longitude": 39.698
        }
        
        # Sync profile
        response = await ac.post("/api/v1/pharmacies/sync-profile", json=payload, headers=headers)
        assert response.status_code == 201
        
        data = response.json()
        assert data["pharmacy_id"] == "mock-auth-sync-uuid-1"
        assert data["business_name"] == "Sync test pharmacy"
        assert data["license_number"] == "PPB-SYNC-999"
        assert data["email"] == "sync@test.com"
        assert data["phone_number"] == "0799999999"
        assert data["latitude"] == -4.046
        assert data["longitude"] == 39.698
        assert data["account_status"] == "PENDING"
        
        # Verify db entry
        node = await crud.get_pharmacy_node(db_session, "mock-auth-sync-uuid-1")
        assert node is not None
        assert node.business_name == "Sync test pharmacy"
        assert node.license_number == "PPB-SYNC-999"
        assert node.email == "sync@test.com"

@pytest.mark.asyncio
async def test_sync_profile_unauthorized():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        payload = {
            "business_name": "Unauth Sync",
            "license_number": "PPB-SYNC-UNAUTH",
            "email": "unauth@test.com",
            "phone_number": "0700000000",
            "latitude": -4.0,
            "longitude": 39.0
        }
        
        # Missing auth header
        response = await ac.post("/api/v1/pharmacies/sync-profile", json=payload)
        assert response.status_code == 401
        
        # Invalid format
        response = await ac.post("/api/v1/pharmacies/sync-profile", json=payload, headers={"Authorization": "Invalid mock-token"})
        assert response.status_code == 401

@pytest.mark.asyncio
async def test_sync_profile_duplicate_conflict(db_session):
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. Seed an existing pharmacy
        existing_profile = schemas.PharmacyProfileSync(
            business_name="Existing Pharmacy",
            license_number="PPB-SYNC-DUP-LICENSE",
            email="existing@test.com",
            phone_number="0712345678",
            latitude=-4.045,
            longitude=39.695
        )
        await crud.create_pharmacy_node(db_session, "mock-existing-pharmacy", existing_profile)
        
        # 2. Try to sync another profile using the same pharmacy_id
        payload_same_id = {
            "business_name": "Duplicate ID Sync",
            "license_number": "PPB-SYNC-NEW-LIC-1",
            "email": "new_email@test.com",
            "phone_number": "0700000001",
            "latitude": -4.04,
            "longitude": 39.69
        }
        response = await ac.post(
            "/api/v1/pharmacies/sync-profile",
            json=payload_same_id,
            headers={"Authorization": "Bearer mock-existing-pharmacy"}
        )
        assert response.status_code == 400
        assert "already synchronized" in response.json()["detail"]

        # 3. Try to sync duplicate license number
        payload_dup_license = {
            "business_name": "Duplicate License Pharmacy",
            "license_number": "PPB-SYNC-DUP-LICENSE",
            "email": "different_email@test.com",
            "phone_number": "0700000002",
            "latitude": -4.04,
            "longitude": 39.69
        }
        response = await ac.post(
            "/api/v1/pharmacies/sync-profile",
            json=payload_dup_license,
            headers={"Authorization": "Bearer mock-new-pharmacy-2"}
        )
        assert response.status_code == 400
        assert "license number is already registered" in response.json()["detail"]

        # 4. Try to sync duplicate email address
        payload_dup_email = {
            "business_name": "Duplicate Email Pharmacy",
            "license_number": "PPB-SYNC-NEW-LIC-2",
            "email": "existing@test.com",
            "phone_number": "0700000003",
            "latitude": -4.04,
            "longitude": 39.69
        }
        response = await ac.post(
            "/api/v1/pharmacies/sync-profile",
            json=payload_dup_email,
            headers={"Authorization": "Bearer mock-new-pharmacy-3"}
        )
        assert response.status_code == 400
        assert "email is already registered" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_and_update_profile(db_session):
    # 1. Setup profile
    profile = schemas.PharmacyProfileSync(
        business_name="Original Name",
        license_number="PPB-PROFILE-123",
        email="profile@test.com",
        phone_number="0711111111",
        latitude=-1.28,
        longitude=36.82
    )
    await crud.create_pharmacy_node(db_session, "mock-profile-user", profile)
    
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        headers = {"Authorization": "Bearer mock-profile-user"}
        
        # 2. Get profile (GET /api/v1/pharmacies/me)
        resp = await ac.get("/api/v1/pharmacies/me", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["business_name"] == "Original Name"
        assert data["email"] == "profile@test.com"
        assert data["latitude"] == pytest.approx(-1.28)
        assert data["longitude"] == pytest.approx(36.82)
        
        # 3. Update profile (PUT /api/v1/pharmacies/me)
        update_payload = {
            "business_name": "Updated Name",
            "phone_number": "0722222222",
            "latitude": -1.29,
            "longitude": 36.83
        }
        resp = await ac.put("/api/v1/pharmacies/me", json=update_payload, headers=headers)
        assert resp.status_code == 200
        data_updated = resp.json()
        assert data_updated["business_name"] == "Updated Name"
        assert data_updated["phone_number"] == "0722222222"
        assert data_updated["latitude"] == pytest.approx(-1.29)
        assert data_updated["longitude"] == pytest.approx(36.83)
        
        # Verify db persistence
        db_node = await crud.get_pharmacy_node(db_session, "mock-profile-user")
        assert db_node.business_name == "Updated Name"
        assert db_node.phone_number == "0722222222"

