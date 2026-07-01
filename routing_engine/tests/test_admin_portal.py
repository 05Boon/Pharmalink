import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.main import app
from app import schemas, crud
from app.models import PharmacyNode, InventoryItem, StockRequest, SystemAdmin, TransactionLog

@pytest.mark.asyncio
async def test_admin_portal_endpoints(db_session: AsyncSession):
    # 0. Cleanup
    await db_session.execute(text("DELETE FROM transaction_logs"))
    await db_session.execute(text("DELETE FROM alert_notifications"))
    await db_session.execute(text("DELETE FROM stock_requests"))
    await db_session.execute(text("DELETE FROM inventory_items"))
    await db_session.execute(text("DELETE FROM pharmacy_nodes WHERE license_number LIKE 'PPB-ADMP-%'"))
    await db_session.execute(text("DELETE FROM system_admins WHERE email = 'admin_portal@test.com'"))
    await db_session.commit()

    # 1. Setup admin
    admin = SystemAdmin(
        admin_id="mock-portal-admin",
        email="admin_portal@test.com",
        role_level=2
    )
    db_session.add(admin)
    
    # 2. Setup node
    node = PharmacyNode(
        pharmacy_id="mock-portal-node",
        business_name="Portal Pending Pharmacy",
        license_number="PPB-ADMP-1",
        email="pending@portal.com",
        phone_number="+254711111111",
        location="POINT(39.698000 -4.046000)",
        account_status="PENDING"
    )
    await db_session.merge(node)
    
    # 3. Setup inventory
    inv = InventoryItem(
        pharmacy_id="mock-portal-node",
        drug_name="Portal Aspirin",
        stock_quantity=10
    )
    await db_session.merge(inv)
    
    # 4. Setup transaction
    req = StockRequest(
        pharmacy_id="mock-portal-node",
        requested_drug="Portal Aspirin",
        required_quantity=5,
        request_status="FULFILLED"
    )
    db_req = await db_session.merge(req)
    await db_session.commit()
    
    txn = TransactionLog(
        request_id=db_req.request_id,
        drug_category="Analgesics",
        final_outcome="FULFILLED_BY_NEIGHBOR"
    )
    db_session.add(txn)
    await db_session.commit()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        headers_user = {"Authorization": "Bearer mock-portal-node"}
        headers_admin = {"Authorization": "Bearer mock-portal-admin"}

        # --- Test 1: Security blocks standard users ---
        resp = await ac.get("/api/v1/admin/transactions", headers=headers_user)
        assert resp.status_code == 403
        
        resp = await ac.get("/api/v1/admin/logs", headers=headers_user)
        assert resp.status_code == 403

        resp = await ac.get("/api/v1/admin/pharmacies/mock-portal-node", headers=headers_user)
        assert resp.status_code == 403

        resp = await ac.get("/api/v1/admin/pharmacies/mock-portal-node/inventory", headers=headers_user)
        assert resp.status_code == 403

        resp = await ac.patch("/api/v1/admin/pharmacies/mock-portal-node/onboarding", json={"approved": True}, headers=headers_user)
        assert resp.status_code == 403

        # --- Test 2: Admin accesses details of specific pharmacy ---
        resp = await ac.get("/api/v1/admin/pharmacies/mock-portal-node", headers=headers_admin)
        assert resp.status_code == 200
        data = resp.json()
        assert data["pharmacy_id"] == "mock-portal-node"
        assert data["account_status"] == "PENDING"

        # --- Test 3: Admin gets specific pharmacy inventory ---
        resp = await ac.get("/api/v1/admin/pharmacies/mock-portal-node/inventory", headers=headers_admin)
        assert resp.status_code == 200
        inv_list = resp.json()
        assert len(inv_list) == 1
        assert inv_list[0]["drug_name"] == "Portal Aspirin"

        # --- Test 4: Admin submits onboarding review decision ---
        resp = await ac.patch(
            "/api/v1/admin/pharmacies/mock-portal-node/onboarding",
            json={"approved": True},
            headers=headers_admin
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["account_status"] == "ACTIVE"

        # Verify in DB
        db_node = await crud.get_pharmacy_node(db_session, "mock-portal-node")
        assert db_node.account_status == "ACTIVE"

        # --- Test 5: Admin retrieves transaction monitoring list ---
        resp = await ac.get("/api/v1/admin/transactions", headers=headers_admin)
        assert resp.status_code == 200
        txn_list = resp.json()
        assert len(txn_list) == 1
        assert txn_list[0]["drug"] == "Portal Aspirin"
        assert txn_list[0]["to"] == "Portal Pending Pharmacy"

        # --- Test 6: Admin retrieves audit log list ---
        resp = await ac.get("/api/v1/admin/logs", headers=headers_admin)
        assert resp.status_code == 200
        log_list = resp.json()
        assert len(log_list) >= 2
        actions = [l["action"] for l in log_list]
        assert any("Pharmacy Registered" in a for a in actions)
