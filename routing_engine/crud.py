from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import Optional, List
from models import StockRequest, AlertNotification
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
