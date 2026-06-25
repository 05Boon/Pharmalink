from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List

from database import get_db
from dependencies import get_current_user_uuid
from models import PharmacyNode, InventoryItem
import crud
import schemas

api_router = APIRouter()

# --- Inventory Endpoints ---

@api_router.get(
    "/inventory",
    response_model=List[schemas.InventoryItemResponse],
    summary="Get authenticated pharmacy's inventory items"
)
async def get_my_inventory(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns a list of all inventory items registered under the authenticated pharmacy's ID.
    """
    return await crud.get_inventory_items(db, pharmacy_id)


@api_router.post(
    "/inventory",
    response_model=schemas.InventoryItemResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add or update a drug in the inventory"
)
async def add_or_update_stock(
    item_in: schemas.InventoryItemCreate,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Adds a new drug to the inventory or updates the stock level if the drug already exists.
    """
    return await crud.create_or_update_inventory_item(db, pharmacy_id, item_in)


@api_router.patch(
    "/inventory/{item_id}",
    response_model=schemas.InventoryItemResponse,
    summary="Update stock quantity of a specific inventory item"
)
async def patch_stock_level(
    item_id: str,
    update_in: schemas.InventoryItemUpdate,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Updates the stock level of a specific drug. 
    Verifies that the target item belongs to the authenticated pharmacy.
    """
    db_item = await crud.get_inventory_item(db, item_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inventory item not found."
        )
    
    # Enforce strict resource ownership validation
    if db_item.pharmacy_id != pharmacy_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permission denied. You cannot modify inventory items belonging to other pharmacies."
        )
        
    return await crud.update_inventory_item_stock(db, item_id, update_in.stock_quantity)


# --- Broadcasts Endpoints ---

@api_router.post(
    "/broadcasts/request",
    response_model=schemas.StockRequestResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a stock request and broadcast alerts to neighbors"
)
async def create_request_and_broadcast(
    request_in: schemas.StockRequestCreateInput,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Creates a new StockRequest, retrieves the pharmacy's geographical location coordinates,
    finds neighboring pharmacies within the radius holding the drug, seeds unread alert records,
    and broadcasts the alert message via real-time WebSockets to connected nodes.
    """
    # 1. Fetch the requesting pharmacy's origin coordinates in EWKT format
    location_query = select(func.ST_AsEWKT(PharmacyNode.location)).where(PharmacyNode.pharmacy_id == pharmacy_id)
    location_result = await db.execute(location_query)
    origin_ewkt = location_result.scalar_one_or_none()
    
    if not origin_ewkt:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Requesting pharmacy profile location is not configured in the database."
        )
        
    # 2. Save the StockRequest entry
    stock_request_data = schemas.StockRequestCreate(
        pharmacy_id=pharmacy_id,
        requested_drug=request_in.requested_drug,
        required_quantity=request_in.required_quantity,
        search_radius_meters=request_in.search_radius_meters
    )
    db_request = await crud.create_stock_request(db, stock_request_data)
    
    # 3. Locate neighbors holding the requested stock within search radius
    neighbors = await crud.find_neighboring_pharmacies(
        db,
        origin_ewkt=origin_ewkt,
        radius_meters=request_in.search_radius_meters,
        drug_name=request_in.requested_drug,
        required_quantity=request_in.required_quantity
    )
    
    # 4. Ingest AlertNotification records and broadcast real-time messages
    from main import manager # Import here to avoid circular dependencies
    
    alerted_count = 0
    for neighbor in neighbors:
        # Prevent self-alerting
        if neighbor.pharmacy_id == pharmacy_id:
            continue
            
        # Create Alert Database entry
        alert_data = schemas.AlertNotificationCreate(
            request_id=db_request.request_id,
            receiving_pharmacy_id=neighbor.pharmacy_id,
            alert_status="UNREAD"
        )
        db_alert = await crud.create_alert_notification(db, alert_data)
        
        # Broadcast alert payload via active websocket connection if online
        alert_payload = {
            "alert_id": db_alert.alert_id,
            "request_id": db_request.request_id,
            "requesting_pharmacy_name": neighbor.business_name,
            "requested_drug": db_request.requested_drug,
            "required_quantity": db_request.required_quantity,
            "created_at": db_request.created_at.isoformat()
        }
        await manager.broadcast_to_pharmacy(neighbor.pharmacy_id, alert_payload)
        alerted_count += 1
        
    # 5. Fetch and return StockRequest with eagerly loaded Alert relationship
    return await crud.get_stock_request(db, db_request.request_id)


@api_router.get(
    "/broadcasts/active-requests",
    response_model=List[schemas.StockRequestResponse],
    summary="Get active stock requests created by the authenticated pharmacy"
)
async def get_my_active_requests(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns all active (PENDING) stock requests created by the authenticated pharmacy.
    """
    return await crud.get_active_stock_requests(db, pharmacy_id)


@api_router.get(
    "/broadcasts/alerts/unread",
    response_model=List[schemas.AlertNotificationDetailResponse],
    summary="Get unread alert notifications sent to the authenticated pharmacy"
)
async def get_my_unread_alerts(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns unread alert notifications targeted at the authenticated pharmacy,
    including details of the stock request and the requesting pharmacy's profile.
    """
    return await crud.get_unread_alerts(db, pharmacy_id)

