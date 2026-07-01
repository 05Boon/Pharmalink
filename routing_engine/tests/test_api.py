import pytest
import asyncio
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.database import get_db
from app.models import PharmacyNode, InventoryItem, StockRequest, AlertNotification
from app.main import app, manager

client = TestClient(app)


@pytest.mark.asyncio
async def test_unauthenticated_api_endpoints():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 1. GET /inventory -> 401 Unauthorized
        resp = await ac.get("/api/v1/inventory")
        assert resp.status_code == 401
        
        # 2. POST /inventory -> 401 Unauthorized
        resp = await ac.post("/api/v1/inventory", json={"drug_name": "Aspirin", "stock_quantity": 10})
        assert resp.status_code == 401
        
        # 3. PATCH /inventory/some-id -> 401 Unauthorized
        resp = await ac.patch("/api/v1/inventory/some-id", json={"stock_quantity": 20})
        assert resp.status_code == 401
        
        # 4. POST /broadcasts/request -> 401 Unauthorized
        resp = await ac.post("/api/v1/broadcasts/request", json={"requested_drug": "Aspirin", "required_quantity": 5})
        assert resp.status_code == 401


@pytest.mark.asyncio
async def test_inventory_crud_and_ownership(db_session: AsyncSession):
    # 0. Cleanup previous test entries by PPB-% license number to remove old run remnants
    await db_session.execute(text("DELETE FROM inventory_items WHERE pharmacy_id IN (SELECT pharmacy_id FROM pharmacy_nodes WHERE license_number LIKE 'PPB-%')"))
    await db_session.execute(text("DELETE FROM pharmacy_nodes WHERE license_number LIKE 'PPB-%'"))
    await db_session.commit()

    # 1. Setup - Create two pharmacies with IDs starting with mock- so the token matches their DB identity
    pharmacy1 = PharmacyNode(
        pharmacy_id="mock-api-node-1",
        business_name="API Pharmacy 1",
        license_number="PPB-API-1",
        email="p1@api.com",
        phone_number="+254711111111",
        location="POINT(39.698000 -4.046000)"
    )
    pharmacy2 = PharmacyNode(
        pharmacy_id="mock-api-node-2",
        business_name="API Pharmacy 2",
        license_number="PPB-API-2",
        email="p2@api.com",
        phone_number="+254722222222",
        location="POINT(39.710000 -4.055000)"
    )
    await db_session.merge(pharmacy1)
    await db_session.merge(pharmacy2)
    await db_session.commit()

    # Use AsyncClient to execute REST calls within the test loop's transaction
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        # 2. Add inventory item for Pharmacy 1 using POST
        headers_p1 = {"Authorization": "Bearer mock-api-node-1"}
        resp = await ac.post(
            "/api/v1/inventory",
            json={"drug_name": "Paracetamol 500mg", "stock_quantity": 50, "drug_category": "Analgesics"},
            headers=headers_p1
        )
        assert resp.status_code == 201
        item = resp.json()
        assert item["drug_name"] == "Paracetamol 500mg"
        assert item["stock_quantity"] == 50
        assert item["pharmacy_id"] == "mock-api-node-1"
        item_id = item["item_id"]

        # 3. Attempt to update Pharmacy 1's item using Pharmacy 2 credentials (PATCH) -> 403 Forbidden
        headers_p2 = {"Authorization": "Bearer mock-api-node-2"}
        resp = await ac.patch(
            f"/api/v1/inventory/{item_id}",
            json={"stock_quantity": 100},
            headers=headers_p2
        )
        assert resp.status_code == 403
        assert "Permission denied" in resp.json()["detail"]

        # 4. Successfully update stock level using Pharmacy 1 credentials (PATCH) -> 200 OK
        resp = await ac.patch(
            f"/api/v1/inventory/{item_id}",
            json={"stock_quantity": 100},
            headers=headers_p1
        )
        assert resp.status_code == 200
        assert resp.json()["stock_quantity"] == 100

        # 5. Fetch inventory items for Pharmacy 1 (GET)
        resp = await ac.get("/api/v1/inventory", headers=headers_p1)
        assert resp.status_code == 200
        items = resp.json()
        assert len(items) == 1
        assert items[0]["item_id"] == item_id


@pytest.mark.asyncio
async def test_spatial_routing_and_websocket_broadcast(db_session: AsyncSession):
    # 0. Cleanup previous entries by PPB-% license number to remove old run remnants
    await db_session.execute(text("DELETE FROM inventory_items WHERE pharmacy_id IN (SELECT pharmacy_id FROM pharmacy_nodes WHERE license_number LIKE 'PPB-%')"))
    await db_session.execute(text("DELETE FROM pharmacy_nodes WHERE license_number LIKE 'PPB-%'"))
    await db_session.commit()

    # 1. Setup - Create requester and neighbor pharmacy nodes
    requester = PharmacyNode(
        pharmacy_id="mock-api-spatial-req",
        business_name="Requester Nyali",
        license_number="PPB-SPATIAL-REQ",
        email="req@spatial.com",
        phone_number="+254700000300",
        location="POINT(39.698434 -4.046956)"  # Nyali Central
    )
    neighbor = PharmacyNode(
        pharmacy_id="mock-api-spatial-neighbor",
        business_name="Neighbor Nyali",
        license_number="PPB-SPATIAL-NEIGHBOR",
        email="neigh@spatial.com",
        phone_number="+254700000400",
        location="POINT(39.698000 -4.046000)"  # ~110m away
    )
    await db_session.merge(requester)
    await db_session.merge(neighbor)
    await db_session.commit()

    # 2. Seed stock for neighbor
    neighbor_stock = InventoryItem(
        item_id="api-spatial-inv",
        pharmacy_id="mock-api-spatial-neighbor",
        drug_name="Ibuprofen 400mg",
        drug_category="NSAIDS",
        stock_quantity=80
    )
    await db_session.merge(neighbor_stock)
    await db_session.commit()

    # 3. Connect neighbor node via WebSocket (using TestClient for websocket sessions)
    with client.websocket_connect("/ws?token=mock-api-spatial-neighbor") as websocket:
        assert "mock-api-spatial-neighbor" in manager.active_connections
        
        # 4. Trigger stock request broadcast using POST /broadcasts/request (using AsyncClient)
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
            headers = {"Authorization": "Bearer mock-api-spatial-req"}
            payload = {
                "requested_drug": "Ibuprofen 400mg",
                "required_quantity": 20,
                "search_radius_meters": 1500
            }
            
            resp = await ac.post("/api/v1/broadcasts/request", json=payload, headers=headers)
            assert resp.status_code == 201
            
            request_resp = resp.json()
            assert request_resp["requested_drug"] == "Ibuprofen 400mg"
            assert request_resp["required_quantity"] == 20
            assert len(request_resp["alerts"]) == 1
            
            # 5. Verify neighbor received the WebSocket alert payload in real-time
            alert_ws_msg = websocket.receive_json()
            assert alert_ws_msg["requested_drug"] == "Ibuprofen 400mg"
            assert alert_ws_msg["required_quantity"] == 20
            assert alert_ws_msg["request_id"] == request_resp["request_id"]
            assert alert_ws_msg["requesting_pharmacy_name"] == "Neighbor Nyali"
