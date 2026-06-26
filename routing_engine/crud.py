from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import cast, func
from geoalchemy2 import Geography
from typing import Optional, List
from models import StockRequest, AlertNotification, PharmacyNode, InventoryItem
import schemas

async def create_stock_request(db: AsyncSession, request: schemas.StockRequestCreate) -> StockRequest:
    """
    Creates a new StockRequest entry in the database.
    """
    db_request = StockRequest(
        pharmacy_id=request.pharmacy_id,
        requested_drug=request.requested_drug,
        required_quantity=request.required_quantity,
        search_radius_meters=request.search_radius_meters
    )
    db.add(db_request)
    await db.commit()
    await db.refresh(db_request)
    return db_request

async def get_stock_request(db: AsyncSession, request_id: str) -> Optional[StockRequest]:
    """
    Fetches a single StockRequest by its ID.
    Uses selectinload to eagerly load the associated AlertNotification alerts 
    in a single query batch to prevent N+1 query overhead.
    """
    stmt = (
        select(StockRequest)
        .where(StockRequest.request_id == request_id)
        .options(selectinload(StockRequest.alerts))
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()

async def create_alert_notification(db: AsyncSession, alert: schemas.AlertNotificationCreate) -> AlertNotification:
    """
    Creates a new AlertNotification entry linked to a StockRequest.
    """
    db_alert = AlertNotification(
        request_id=alert.request_id,
        receiving_pharmacy_id=alert.receiving_pharmacy_id,
        alert_status=alert.alert_status
    )
    db.add(db_alert)
    await db.commit()
    await db.refresh(db_alert)
    return db_alert

async def get_alert_notification(db: AsyncSession, alert_id: str) -> Optional[AlertNotification]:
    """
    Fetches an alert notification by its ID.
    """
    stmt = select(AlertNotification).where(AlertNotification.alert_id == alert_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()

async def update_stock_request_status(db: AsyncSession, request_id: str, status: str) -> Optional[StockRequest]:
    """
    Updates the status of a stock request.
    """
    db_request = await get_stock_request(db, request_id)
    if db_request:
        db_request.request_status = status
        db.add(db_request)
        await db.commit()
        await db.refresh(db_request)
    return db_request

async def update_alert_status(db: AsyncSession, alert_id: str, status: str) -> Optional[AlertNotification]:
    """
    Updates the read/unread status of an alert notification.
    """
    db_alert = await get_alert_notification(db, alert_id)
    if db_alert:
        db_alert.alert_status = status
        db.add(db_alert)
        await db.commit()
        await db.refresh(db_alert)
    return db_alert

async def find_neighboring_pharmacies(
    db: AsyncSession,
    origin_ewkt: str,
    radius_meters: float,
    drug_name: str,
    required_quantity: int
) -> List[PharmacyNode]:
    """
    Finds neighboring pharmacy nodes within a given search radius (in meters)
    that hold a sufficient quantity of a specified drug.
    Uses PostGIS ST_DWithin function over geography cast of SRID 4326.
    """
    stmt = (
        select(PharmacyNode)
        .join(InventoryItem, PharmacyNode.pharmacy_id == InventoryItem.pharmacy_id)
        .where(
            func.ST_DWithin(
                cast(PharmacyNode.location, Geography),
                cast(func.ST_GeomFromEWKT(origin_ewkt), Geography),
                radius_meters
            )
        )
        .where(InventoryItem.drug_name == drug_name)
        .where(InventoryItem.stock_quantity >= required_quantity)
        .distinct()
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())

async def get_inventory_items(db: AsyncSession, pharmacy_id: str) -> List[InventoryItem]:
    """
    Retrieves all inventory items for a given pharmacy_id.
    """
    stmt = select(InventoryItem).where(InventoryItem.pharmacy_id == pharmacy_id)
    result = await db.execute(stmt)
    return list(result.scalars().all())

async def get_inventory_item(db: AsyncSession, item_id: str) -> Optional[InventoryItem]:
    """
    Retrieves a single inventory item by its item_id.
    """
    stmt = select(InventoryItem).where(InventoryItem.item_id == item_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()

async def create_or_update_inventory_item(
    db: AsyncSession,
    pharmacy_id: str,
    item: schemas.InventoryItemCreate
) -> InventoryItem:
    """
    Adds a new drug to the inventory or updates its stock level if it already exists.
    """
    stmt = (
        select(InventoryItem)
        .where(InventoryItem.pharmacy_id == pharmacy_id)
        .where(InventoryItem.drug_name == item.drug_name)
    )
    result = await db.execute(stmt)
    db_item = result.scalar_one_or_none()
    
    if db_item:
        db_item.stock_quantity = item.stock_quantity
        if item.drug_category:
            db_item.drug_category = item.drug_category
    else:
        db_item = InventoryItem(
            pharmacy_id=pharmacy_id,
            drug_name=item.drug_name,
            drug_category=item.drug_category,
            stock_quantity=item.stock_quantity
        )
        db.add(db_item)
        
    await db.commit()
    await db.refresh(db_item)
    return db_item

async def update_inventory_item_stock(db: AsyncSession, item_id: str, stock_quantity: int) -> Optional[InventoryItem]:
    """
    Updates the stock level of a specific inventory item.
    """
    db_item = await get_inventory_item(db, item_id)
    if db_item:
        db_item.stock_quantity = stock_quantity
        db.add(db_item)
        await db.commit()
        await db.refresh(db_item)
    return db_item


async def get_pharmacy_node(db: AsyncSession, pharmacy_id: str) -> Optional[PharmacyNode]:
    """
    Retrieves a single pharmacy node by its pharmacy_id.
    """
    stmt = select(PharmacyNode).where(PharmacyNode.pharmacy_id == pharmacy_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_pharmacy_node_by_license(db: AsyncSession, license_number: str) -> Optional[PharmacyNode]:
    """
    Retrieves a pharmacy node by its license_number.
    """
    stmt = select(PharmacyNode).where(PharmacyNode.license_number == license_number)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_pharmacy_node_by_email(db: AsyncSession, email: str) -> Optional[PharmacyNode]:
    """
    Retrieves a pharmacy node by its email address.
    """
    stmt = select(PharmacyNode).where(PharmacyNode.email == email)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def create_pharmacy_node(
    db: AsyncSession,
    pharmacy_id: str,
    profile: schemas.PharmacyProfileSync
) -> PharmacyNode:
    """
    Creates a new PharmacyNode entry using the provided profile details and custom primary key.
    """
    point_wkt = f"POINT({profile.longitude} {profile.latitude})"
    db_node = PharmacyNode(
        pharmacy_id=pharmacy_id,
        business_name=profile.business_name,
        license_number=profile.license_number,
        email=profile.email,
        phone_number=profile.phone_number,
        location=f"SRID=4326;{point_wkt}",
        account_status="ACTIVE"
    )
    db.add(db_node)
    await db.commit()
    await db.refresh(db_node)
    return db_node


async def get_active_stock_requests(db: AsyncSession, pharmacy_id: str) -> List[StockRequest]:
    """
    Retrieves all active (PENDING) stock requests created by a pharmacy.
    Eagerly loads the associated alerts relation.
    """
    stmt = (
        select(StockRequest)
        .where(StockRequest.pharmacy_id == pharmacy_id)
        .where(StockRequest.request_status == "PENDING")
        .options(selectinload(StockRequest.alerts))
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_unread_alerts(db: AsyncSession, pharmacy_id: str) -> List[AlertNotification]:
    """
    Retrieves incoming, unread alert notifications sent to a pharmacy.
    Eagerly loads both the stock request and the requesting pharmacy's profile details.
    """
    stmt = (
        select(AlertNotification)
        .where(AlertNotification.receiving_pharmacy_id == pharmacy_id)
        .where(AlertNotification.alert_status == "UNREAD")
        .options(
            selectinload(AlertNotification.request)
            .selectinload(StockRequest.pharmacy)
        )
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def update_pharmacy_status(db: AsyncSession, pharmacy_id: str, account_status: str) -> Optional[PharmacyNode]:
    """
    Updates the account status of a pharmacy node.
    """
    db_node = await get_pharmacy_node(db, pharmacy_id)
    if db_node:
        db_node.account_status = account_status
        db.add(db_node)
        await db.commit()
        await db.refresh(db_node)
    return db_node




