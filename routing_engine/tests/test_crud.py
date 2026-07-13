import pytest
import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.exc import MissingGreenlet

from app.models import PharmacyNode, StockRequest, AlertNotification
from app import schemas
from app import crud


@pytest.mark.asyncio
async def test_create_and_fetch_stock_request_with_eager_alerts(db_session: AsyncSession):
    # 1. Setup - Create requesting and receiving pharmacies in Mombasa (SRID 4326)
    req_pharmacy = PharmacyNode(
        pharmacy_id="req-pharmacy-uuid-1111",
        business_name="Requesting Pharmacy",
        license_number="PPB-TEST-REQ-1111",
        email="req@test.com",
        phone_number="+254700000001",
        location="POINT(39.698434 -4.046956)"  # Nyali, Mombasa
    )
    rec_pharmacy = PharmacyNode(
        pharmacy_id="rec-pharmacy-uuid-2222",
        business_name="Receiving Pharmacy",
        license_number="PPB-TEST-REC-2222",
        email="rec@test.com",
        phone_number="+254700000002",
        location="POINT(39.700000 -4.050000)"  # Nearby Nyali
    )
    
    # Merge/Add to database (using merge to avoid conflicts if run multiple times)
    await db_session.merge(req_pharmacy)
    await db_session.merge(rec_pharmacy)
    await db_session.commit()

    # 2. Test Pydantic Schema Validation for StockRequestCreate
    request_input = schemas.StockRequestCreate(
        pharmacy_id="req-pharmacy-uuid-1111",
        requested_drug="Amoxicillin 500mg",
        required_quantity=150,
        search_radius_meters=1500
    )
    
    # 3. Create Stock Request
    db_request = await crud.create_stock_request(db_session, request_input)
    assert db_request.request_id is not None
    assert db_request.requested_drug == "Amoxicillin 500mg"
    assert db_request.required_quantity == 150

    # 4. Create Alert linked to the request
    alert_input = schemas.AlertNotificationCreate(
        request_id=db_request.request_id,
        receiving_pharmacy_id="rec-pharmacy-uuid-2222",
        alert_status="UNREAD"
    )
    db_alert = await crud.create_alert_notification(db_session, alert_input)
    assert db_alert.alert_id is not None
    assert db_alert.request_id == db_request.request_id

    # 5. Fetch StockRequest using get_stock_request (eager loading check)
    fetched_request = await crud.get_stock_request(db_session, db_request.request_id)
    assert fetched_request is not None
    
    # Verify that the alerts list is eagerly loaded and doesn't raise MissingGreenlet exception
    try:
        alerts = fetched_request.alerts
        assert len(alerts) >= 1
        assert alerts[0].receiving_pharmacy_id == "rec-pharmacy-uuid-2222"
    except MissingGreenlet:
        pytest.fail("Failed: AlertNotifications were not eagerly loaded, causing MissingGreenlet exception.")

@pytest.mark.asyncio
async def test_validation_errors():
    # Verify that invalid quantities or search radius raise validation errors
    with pytest.raises(ValueError):
        schemas.StockRequestCreate(
            pharmacy_id="req-pharmacy-uuid-1111",
            requested_drug="Amoxicillin 500mg",
            required_quantity=-10, # Invalid quantity
            search_radius_meters=1500
        )

    with pytest.raises(ValueError):
        schemas.StockRequestCreate(
            pharmacy_id="req-pharmacy-uuid-1111",
            requested_drug="Amoxicillin 500mg",
            required_quantity=10,
            search_radius_meters=-50 # Invalid search radius
        )

@pytest.mark.asyncio
async def test_ssot_category_injection(db_session: AsyncSession):
    pharmacy = PharmacyNode(
        pharmacy_id="ssot-pharm-123",
        business_name="SSOT Pharmacy",
        license_number="PPB-SSOT-123",
        email="ssot@test.com",
        phone_number="+254700000003",
        location="POINT(36.8219 -1.2921)"  # Nairobi
    )
    await db_session.merge(pharmacy)
    await db_session.commit()

    req_input = schemas.StockRequestCreate(
        pharmacy_id="ssot-pharm-123",
        requested_drug="paracetamol",
        required_quantity=50,
        search_radius_meters=1000
    )
    db_req = await crud.create_stock_request(db_session, req_input)
    print(f"\n[SSOT INJECTION] StockRequest Drug: '{db_req.requested_drug}' -> Category: '{db_req.drug_category}'")
    assert db_req.drug_category == "Antipyretic/Analgesic"

    inv_input = schemas.InventoryItemCreate(
        drug_name="amoxicillin",
        stock_quantity=100
    )
    db_inv = await crud.create_or_update_inventory_item(db_session, "ssot-pharm-123", inv_input)
    print(f"[SSOT INJECTION] InventoryItem Drug: '{db_inv.drug_name}' -> Category: '{db_inv.drug_category}'")
    assert db_inv.drug_category == "Antibiotic"

@pytest.mark.asyncio
async def test_geocode_shift_on_pharmacy_creation(db_session: AsyncSession):
    profile = schemas.PharmacyProfileSync(
        business_name="Geocode Pharmacy",
        license_number="PPB-GEO-123",
        email="geo@test.com",
        phone_number="+254700000004",
        latitude=-1.2921,
        longitude=36.8219
    )
    db_node = await crud.create_pharmacy_node(db_session, "geo-pharm-123", profile)
    print(f"\n[GEOCODE SHIFT] Coordinates: ({profile.latitude}, {profile.longitude}) -> Location: '{db_node.general_location}'")
    assert db_node.general_location is not None
    assert "Nairobi" in db_node.general_location
