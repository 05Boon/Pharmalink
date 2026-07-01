import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.main import app
from app import schemas, crud
from app.models import PharmacyNode, InventoryItem, StockRequest, AlertNotification

@pytest.mark.asyncio
async def test_dashboard_and_respond_flow(db_session: AsyncSession):
    # 0. Cleanup previous test nodes
    await db_session.execute(text("DELETE FROM transaction_logs"))
    await db_session.execute(text("DELETE FROM alert_notifications"))
    await db_session.execute(text("DELETE FROM stock_requests"))
    await db_session.execute(text("DELETE FROM inventory_items"))
    await db_session.execute(text("DELETE FROM pharmacy_nodes WHERE license_number LIKE 'PPB-DASH-%'"))
    await db_session.commit()

    # 1. Setup user nodes
    user_pharmacy = PharmacyNode(
        pharmacy_id="mock-dash-user",
        business_name="Dash Owner Pharmacy",
        license_number="PPB-DASH-1",
        email="owner@dash.com",
        phone_number="+254711111111",
        location="POINT(39.698000 -4.046000)"
    )
    neighbor_pharmacy = PharmacyNode(
        pharmacy_id="mock-dash-neighbor",
        business_name="Dash Neighbor Pharmacy",
        license_number="PPB-DASH-2",
        email="neighbor@dash.com",
        phone_number="+254722222222",
        location="POINT(39.700000 -4.048000)"
    )
    await db_session.merge(user_pharmacy)
    await db_session.merge(neighbor_pharmacy)
    await db_session.commit()

    # 2. Seed low stock items and standard items for the owner
    item_low = InventoryItem(
        pharmacy_id="mock-dash-user",
        drug_name="Low Stock Aspirin",
        stock_quantity=5,
        drug_category="Analgesics"
    )
    item_high = InventoryItem(
        pharmacy_id="mock-dash-user",
        drug_name="High Stock Paracetamol",
        stock_quantity=150,
        drug_category="Analgesics"
    )
    await db_session.merge(item_low)
    await db_session.merge(item_high)
    await db_session.commit()

    # 3. Create an active request sent by user
    req_out = StockRequest(
        pharmacy_id="mock-dash-user",
        requested_drug="Low Stock Aspirin",
        required_quantity=20,
        request_status="PENDING"
    )
    db_req_out = await db_session.merge(req_out)
    await db_session.commit()

    # 4. Create an incoming request sent by neighbor triggering an alert for user
    req_in = StockRequest(
        pharmacy_id="mock-dash-neighbor",
        requested_drug="Amoxicillin 500mg",
        required_quantity=10,
        request_status="PENDING"
    )
    db_req_in = await db_session.merge(req_in)
    await db_session.commit()

    alert_in = AlertNotification(
        request_id=db_req_in.request_id,
        receiving_pharmacy_id="mock-dash-user",
        alert_status="UNREAD"
    )
    await db_session.merge(alert_in)
    await db_session.commit()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        headers_user = {"Authorization": "Bearer mock-dash-user"}

        # TEST 1: GET /api/v1/dashboard
        resp = await ac.get("/api/v1/dashboard", headers=headers_user)
        assert resp.status_code == 200
        dash_data = resp.json()

        # Stats validation
        assert dash_data["stats"]["active_queries"] == 1
        assert dash_data["stats"]["requests_received"] == 1
        assert dash_data["stats"]["completed"] == 0

        # Lists validation
        assert len(dash_data["recent_requests"]) == 1
        assert dash_data["recent_requests"][0]["drug_name"] == "Amoxicillin 500mg"
        assert dash_data["recent_requests"][0]["source"] == "Dash Neighbor Pharmacy"
        assert dash_data["recent_requests"][0]["status"] == "UNREAD"

        assert len(dash_data["active_queries"]) == 1
        assert dash_data["active_queries"][0]["drug_name"] == "Low Stock Aspirin"
        assert "20 units" in dash_data["active_queries"][0]["meta"]

        assert len(dash_data["low_stock_items"]) == 1
        assert dash_data["low_stock_items"][0]["drug_name"] == "Low Stock Aspirin"
        assert dash_data["low_stock_items"][0]["stock_quantity"] == 5

        # TEST 2: GET /api/v1/requests
        resp = await ac.get("/api/v1/requests", headers=headers_user)
        assert resp.status_code == 200
        req_list = resp.json()
        assert len(req_list) == 2

        # TEST 3: GET /api/v1/alerts
        resp = await ac.get("/api/v1/alerts", headers=headers_user)
        assert resp.status_code == 200
        alert_list = resp.json()
        assert len(alert_list) == 1
        assert alert_list[0]["receiving_pharmacy_id"] == "mock-dash-user"

        # TEST 4: PATCH /api/v1/requests/{request_id}/respond
        resp = await ac.patch(
            f"/api/v1/requests/{db_req_in.request_id}/respond",
            json={"status": "ACCEPTED"},
            headers=headers_user
        )
        assert resp.status_code == 200
        respond_data = resp.json()
        assert respond_data["request_status"] == "FULFILLED"

        # Verify completed stat updates for the creator (neighbor)
        headers_neighbor = {"Authorization": "Bearer mock-dash-neighbor"}
        resp = await ac.get("/api/v1/dashboard", headers=headers_neighbor)
        dash_neighbor = resp.json()
        assert dash_neighbor["stats"]["completed"] == 1
