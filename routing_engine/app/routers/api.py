from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List

from app.database import get_db
from app.dependencies import get_current_user_uuid
from app.models import PharmacyNode, InventoryItem
from app import crud
from app import schemas

api_router = APIRouter()


# --- Profile Endpoints ---

@api_router.get(
    "/profile",
    response_model=schemas.PharmacyNodeResponse,
    summary="Get the authenticated pharmacy's profile"
)
async def get_my_profile(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieves the authenticated pharmacy's profile.
    """
    db_node = await crud.get_pharmacy_node(db, pharmacy_id)
    if not db_node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy profile not found."
        )

    coord_query = select(
        func.ST_X(PharmacyNode.location),
        func.ST_Y(PharmacyNode.location)
    ).where(PharmacyNode.pharmacy_id == pharmacy_id)
    coord_result = await db.execute(coord_query)
    coord = coord_result.first()
    
    longitude = coord[0] if coord else 0.0
    latitude = coord[1] if coord else 0.0

    return schemas.PharmacyNodeResponse(
        pharmacy_id=db_node.pharmacy_id,
        business_name=db_node.business_name,
        license_number=db_node.license_number,
        email=db_node.email,
        phone_number=db_node.phone_number,
        latitude=latitude,
        longitude=longitude,
        general_location=db_node.general_location,
        account_status=db_node.account_status,
        created_at=db_node.created_at
    )


@api_router.patch(
    "/profile",
    response_model=schemas.PharmacyNodeResponse,
    summary="Update the authenticated pharmacy's profile"
)
async def update_my_profile(
    profile_update: schemas.PharmacyProfileUpdate,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Updates the authenticated pharmacy's profile fields.
    Strictly locks down geographic and identity fields by ignoring them.
    """
    db_node = await crud.update_pharmacy_profile(db, pharmacy_id, profile_update)
    if not db_node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy profile not found."
        )

    coord_query = select(
        func.ST_X(PharmacyNode.location),
        func.ST_Y(PharmacyNode.location)
    ).where(PharmacyNode.pharmacy_id == pharmacy_id)
    coord_result = await db.execute(coord_query)
    coord = coord_result.first()
    
    longitude = coord[0] if coord else 0.0
    latitude = coord[1] if coord else 0.0

    return schemas.PharmacyNodeResponse(
        pharmacy_id=db_node.pharmacy_id,
        business_name=db_node.business_name,
        license_number=db_node.license_number,
        email=db_node.email,
        phone_number=db_node.phone_number,
        latitude=latitude,
        longitude=longitude,
        general_location=db_node.general_location,
        account_status=db_node.account_status,
        created_at=db_node.created_at
    )


@api_router.get(
    "/drugs/search",
    response_model=List[dict],
    summary="Search pharmacies by drug name"
)
async def search_drugs(
    query: str = Query(..., min_length=1),
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Searches inventory across pharmacies for drug names matching the query.
    Excludes the authenticated pharmacy from results.
    """
    return await crud.search_drugs(
        db,
        query=query.strip(),
        exclude_pharmacy_id=pharmacy_id,
    )

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


@api_router.delete(
    "/inventory/{item_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete an inventory item"
)
async def delete_stock_item(
    item_id: str,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Deletes a specific inventory item. 
    Verifies that the target item belongs to the authenticated pharmacy.
    """
    db_item = await crud.get_inventory_item(db, item_id)
    if not db_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inventory item not found."
        )
    
    if db_item.pharmacy_id != pharmacy_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Permission denied. You cannot modify inventory items belonging to other pharmacies."
        )
        
    await crud.delete_inventory_item(db, item_id)
    return None


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

    requester_node = await crud.get_pharmacy_node(db, pharmacy_id)
    requester_name = (
        requester_node.business_name if requester_node else "Requesting Pharmacy"
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
    from app.main import manager # Import here to avoid circular dependencies
    
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
            "requesting_pharmacy_name": requester_name,
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


@api_router.patch(
    "/requests/{request_id}/respond",
    response_model=schemas.StockRequestResponse,
    summary="Accept or decline an incoming stock request alert"
)
async def respond_to_request(
    request_id: str,
    payload: schemas.RequestResponseInput,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Allows a neighbor to accept or decline a stock request alert.
    If accepted, status of the parent request becomes FULFILLED.
    """
    updated_request = await crud.respond_to_stock_request(db, pharmacy_id, request_id, payload.status)
    if not updated_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Stock request alert notification not found for this pharmacy."
        )

    if payload.status == "ACCEPTED":
        responder = await crud.get_pharmacy_node(db, pharmacy_id)
        accepted_alert = next(
            (
                alert
                for alert in updated_request.alerts
                if alert.receiving_pharmacy_id == pharmacy_id
                and alert.alert_status == "ACCEPTED"
            ),
            None,
        )

        from app.main import manager

        await manager.broadcast_to_pharmacy(
            updated_request.pharmacy_id,
            {
                "event": "REQUEST_ACCEPTED",
                "request_id": updated_request.request_id,
                "requested_drug": updated_request.requested_drug,
                "accepted_at": (
                    accepted_alert.delivered_at.isoformat()
                    if accepted_alert and accepted_alert.delivered_at
                    else None
                ),
                "accepted_by_pharmacy": {
                    "pharmacy_id": responder.pharmacy_id,
                    "business_name": responder.business_name,
                    "email": responder.email,
                    "phone_number": responder.phone_number,
                }
                if responder
                else None,
            },
        )

    return updated_request


@api_router.get(
    "/requests",
    response_model=List[schemas.StockRequestResponse],
    summary="Get all requests relevant to the authenticated pharmacy"
)
async def get_my_requests(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns all stock requests created by the pharmacy OR sent as alerts to the pharmacy.
    """
    return await crud.get_user_relevant_requests(db, pharmacy_id)


@api_router.get(
    "/alerts",
    response_model=List[schemas.AlertNotificationDetailResponse],
    summary="Get all alert notifications targeted at the authenticated pharmacy"
)
async def get_my_alerts(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns all alert notifications (both read and unread) targeted at the pharmacy.
    """
    return await crud.get_all_user_alerts(db, pharmacy_id)


@api_router.get(
    "/dashboard",
    response_model=schemas.DashboardResponse,
    summary="Consolidate dashboard metrics and lists for the pharmacy owner"
)
async def get_dashboard(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Aggregates active outgoing queries count, incoming requests count,
    completed transactions count, recent requests list, active queries list,
    and low stock inventory items.
    """
    return await crud.get_dashboard_metrics(db, pharmacy_id)


@api_router.get(
    "/transactions",
    response_model=List[dict],
    summary="Get transaction history relevant to the authenticated pharmacy"
)
async def get_transactions_history(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns transaction logs where the pharmacy participated as requester
    or as the accepting responder.
    """
    return await crud.get_user_transaction_history(db, pharmacy_id)


@api_router.get(
    "/requests/sent/current",
    response_model=schemas.StockRequestResponse,
    summary="Get the most recent stock request sent by the authenticated pharmacy"
)
async def get_current_sent_request(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    request = await crud.get_last_sent_request_with_responder(db, pharmacy_id)
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No sent stock requests found for this pharmacy."
        )
    return request


@api_router.get(
    "/requests/sent",
    response_model=List[schemas.StockRequestResponse],
    summary="Get all stock requests sent by the authenticated pharmacy"
)
async def get_sent_requests(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns all sent requests, including accepter pharmacy details when available.
    """
    return await crud.get_sent_requests_with_responder(db, pharmacy_id)


@api_router.get(
    "/requests/accepted/current",
    response_model=schemas.StockRequestResponse,
    summary="Get the most recent stock request accepted by the authenticated pharmacy"
)
async def get_current_accepted_request(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    request = await crud.get_last_accepted_request(db, pharmacy_id)
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No accepted stock requests found for this pharmacy."
        )
    return request



