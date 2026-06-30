import pytest
from httpx import AsyncClient, ASGITransport

from database import get_db
import crud
import schemas
from main import app


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
        response = await ac.post("/api/pharmacies/sync-profile", json=payload, headers=headers)
        assert response.status_code == 201
        
        data = response.json()
        assert data["pharmacy_id"] == "mock-auth-sync-uuid-1"
        assert data["business_name"] == "Sync test pharmacy"
        assert data["license_number"] == "PPB-SYNC-999"
        assert data["email"] == "sync@test.com"
        assert data["phone_number"] == "0799999999"
        assert data["latitude"] == -4.046
        assert data["longitude"] == 39.698
        assert data["account_status"] == "ACTIVE"
        
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
        response = await ac.post("/api/pharmacies/sync-profile", json=payload)
        assert response.status_code == 401
        
        # Invalid format
        response = await ac.post("/api/pharmacies/sync-profile", json=payload, headers={"Authorization": "Invalid mock-token"})
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
            "/api/pharmacies/sync-profile",
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
            "/api/pharmacies/sync-profile",
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
            "/api/pharmacies/sync-profile",
            json=payload_dup_email,
            headers={"Authorization": "Bearer mock-new-pharmacy-3"}
        )
        assert response.status_code == 400
        assert "email is already registered" in response.json()["detail"]
