from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from sqlalchemy import cast, func, or_, Numeric
from geoalchemy2 import Geography
from typing import Optional, List
from app.models import StockRequest, AlertNotification, PharmacyNode, InventoryItem, TransactionLog, SystemAdmin
from app import schemas
import datetime

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
        .options(selectinload(StockRequest.alerts), selectinload(StockRequest.pharmacy))
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

    Drug name matching is case-insensitive and partial (same semantics as
    search_drugs) so that a request for "panadol" correctly matches an
    inventory row stored as "Panadol Extra 500mg", instead of silently
    finding zero neighbors on an exact-match miss.
    """
    normalized_drug_name = drug_name.strip().lower()
    stmt = (
        select(PharmacyNode)
        .join(InventoryItem, PharmacyNode.pharmacy_id == InventoryItem.pharmacy_id)
        .where(
            # Keep only pharmacies whose point is inside the requested radius.
            func.ST_DWithin(
                cast(PharmacyNode.location, Geography),
                cast(func.ST_GeomFromEWKT(origin_ewkt), Geography),
                radius_meters
            )
        )
        # Apply case-insensitive partial matching on drug name.
        .where(func.lower(InventoryItem.drug_name).like(f"%{normalized_drug_name}%"))
        # Ensure the neighbor can satisfy the requested quantity.
        .where(InventoryItem.stock_quantity >= required_quantity)
        .distinct()
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def search_drugs(
    db: AsyncSession,
    query: str,
    exclude_pharmacy_id: Optional[str] = None,
    limit: int = 50,
) -> List[dict]:
    """
    Searches inventory by partial drug name and returns display-ready rows
    for the client search results page.
    """
    normalized_query = query.strip()
    if not normalized_query:
        return []

    stmt = (
        select(InventoryItem, PharmacyNode.business_name)
        .join(PharmacyNode, PharmacyNode.pharmacy_id == InventoryItem.pharmacy_id)
        .where(func.lower(InventoryItem.drug_name).like(f"%{normalized_query.lower()}%"))
        .order_by(InventoryItem.stock_quantity.desc(), InventoryItem.drug_name.asc())
        .limit(limit)
    )

    if exclude_pharmacy_id:
        stmt = stmt.where(InventoryItem.pharmacy_id != exclude_pharmacy_id)

    result = await db.execute(stmt)
    rows = result.all()

    return [
        {
            "pharmacy": business_name,
            "name": business_name,
            "pharmacy_id": item.pharmacy_id,
            "drug_name": item.drug_name,
            "stock": item.stock_quantity,
            "quantity": item.stock_quantity,
            "distance": "-",
            "price": "-",
        }
        for item, business_name in rows
    ]

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


async def delete_inventory_item(db: AsyncSession, item_id: str) -> bool:
    """
    Deletes an inventory item.
    """
    db_item = await get_inventory_item(db, item_id)
    if db_item:
        await db.delete(db_item)
        await db.commit()
        return True
    return False


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
        .options(selectinload(StockRequest.alerts), selectinload(StockRequest.pharmacy))
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


async def get_outbreaks_analytics(db: AsyncSession, days: int) -> List[dict]:
    """
    Aggregates stock requests created within the last `days` days.
    Groups by requested_drug, calculates request frequency, and uses PostGIS functions
    ST_Collect and ST_Centroid to determine the geographical center of requests.
    """
    start_time = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None) - datetime.timedelta(days=days)
    
    stmt = (
        select(
            StockRequest.requested_drug,
            func.count(StockRequest.request_id).label("request_frequency"),
            # Compute a centroid from grouped request locations for map visualization.
            func.ST_X(func.ST_Centroid(func.ST_Collect(PharmacyNode.location))).label("centroid_longitude"),
            func.ST_Y(func.ST_Centroid(func.ST_Collect(PharmacyNode.location))).label("centroid_latitude")
        )
        .join(PharmacyNode, StockRequest.pharmacy_id == PharmacyNode.pharmacy_id)
        .where(StockRequest.created_at >= start_time)
        .group_by(StockRequest.requested_drug)
    )
    
    result = await db.execute(stmt)
    rows = result.all()
    
    return [
        {
            "requested_drug": row.requested_drug,
            "request_frequency": row.request_frequency,
            "centroid_longitude": row.centroid_longitude if row.centroid_longitude is not None else 0.0,
            "centroid_latitude": row.centroid_latitude if row.centroid_latitude is not None else 0.0
        }
        for row in rows
    ]


async def generate_admin_report(db: AsyncSession, days: int) -> dict:
    """
    Builds an admin report snapshot for a configurable time window.
    """
    now_utc = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
    start_time = now_utc - datetime.timedelta(days=days)

    # Snapshot core operational totals for the selected window.
    total_nodes_result = await db.execute(select(func.count(PharmacyNode.pharmacy_id)))
    active_nodes_result = await db.execute(
        select(func.count(PharmacyNode.pharmacy_id)).where(
            func.upper(PharmacyNode.account_status) == "ACTIVE"
        )
    )
    total_requests_result = await db.execute(
        select(func.count(StockRequest.request_id)).where(StockRequest.created_at >= start_time)
    )
    fulfilled_requests_result = await db.execute(
        select(func.count(StockRequest.request_id))
        .where(StockRequest.created_at >= start_time)
        .where(func.upper(StockRequest.request_status) == "FULFILLED")
    )
    total_transactions_result = await db.execute(
        select(func.count(TransactionLog.log_id)).where(TransactionLog.resolved_at >= start_time)
    )

    total_nodes = int(total_nodes_result.scalar() or 0)
    active_nodes = int(active_nodes_result.scalar() or 0)
    suspended_nodes = max(total_nodes - active_nodes, 0)
    total_requests = int(total_requests_result.scalar() or 0)
    fulfilled_requests = int(fulfilled_requests_result.scalar() or 0)
    total_transactions = int(total_transactions_result.scalar() or 0)

    # Reuse outbreak analytics so report cards and maps stay consistent.
    outbreaks = await get_outbreaks_analytics(db, days)

    # Rank top requested drugs in the selected report window.
    top_drugs_stmt = (
        select(
            StockRequest.requested_drug.label("drug_name"),
            func.count(StockRequest.request_id).label("request_count"),
        )
        .where(StockRequest.created_at >= start_time)
        .group_by(StockRequest.requested_drug)
        .order_by(func.count(StockRequest.request_id).desc(), StockRequest.requested_drug.asc())
        .limit(5)
    )
    top_drugs_result = await db.execute(top_drugs_stmt)
    top_drugs = [
        {
            "drug_name": row.drug_name,
            "request_count": int(row.request_count or 0),
        }
        for row in top_drugs_result.all()
    ]

    # Build area-level demand intelligence on an ~11km grid (0.1 degrees).
    area_demand_stmt = (
        select(
            func.round(cast(func.ST_Y(PharmacyNode.location), Numeric), 1).label("area_lat"),
            func.round(cast(func.ST_X(PharmacyNode.location), Numeric), 1).label("area_lon"),
            StockRequest.requested_drug.label("drug_name"),
            func.count(StockRequest.request_id).label("request_count"),
        )
        .join(PharmacyNode, StockRequest.pharmacy_id == PharmacyNode.pharmacy_id)
        .where(StockRequest.created_at >= start_time)
        .group_by("area_lat", "area_lon", StockRequest.requested_drug)
        .order_by(
            func.round(cast(func.ST_Y(PharmacyNode.location), Numeric), 1).asc(),
            func.round(cast(func.ST_X(PharmacyNode.location), Numeric), 1).asc(),
            func.count(StockRequest.request_id).desc(),
            StockRequest.requested_drug.asc(),
        )
    )
    area_demand_result = await db.execute(area_demand_stmt)
    area_rows = area_demand_result.all()

    area_totals: dict[tuple[float, float], int] = {}
    area_top_drug: dict[tuple[float, float], dict] = {}
    for row in area_rows:
        lat = float(row.area_lat or 0.0)
        lon = float(row.area_lon or 0.0)
        key = (lat, lon)
        count = int(row.request_count or 0)

        area_totals[key] = area_totals.get(key, 0) + count
        if key not in area_top_drug:
            area_top_drug[key] = {
                "area_label": f"Lat {lat:.1f}, Lon {lon:.1f}",
                "area_latitude": lat,
                "area_longitude": lon,
                "top_drug": row.drug_name,
                "request_count": count,
            }

    top_drugs_by_area = [
        {
            **item,
            "total_requests_in_area": area_totals.get((item["area_latitude"], item["area_longitude"]), 0),
        }
        for item in area_top_drug.values()
    ]
    top_drugs_by_area.sort(
        key=lambda item: (
            -int(item["total_requests_in_area"]),
            -int(item["request_count"]),
            item["area_label"],
        )
    )

    # Dashboard cards are intentionally short so they can be rendered as tiles.
    cards = [
        {
            "title": "Network Nodes",
            "description": f"{total_nodes} total | {active_nodes} active | {suspended_nodes} suspended",
            "icon": "medication",
        },
        {
            "title": "Stock Requests",
            "description": f"{total_requests} requests in last {days} days",
            "icon": "bar_chart",
        },
        {
            "title": "Fulfillment Performance",
            "description": f"{fulfilled_requests} fulfilled | {total_transactions} transaction logs",
            "icon": "assessment",
        },
        {
            "title": "Outbreak Clusters",
            "description": f"{len(outbreaks)} geo-clusters detected in the selected window",
            "icon": "bar_chart",
        },
    ]

    return {
        "generated_at": now_utc,
        "timeframe_days": days,
        "cards": cards,
        "top_requested_drugs": top_drugs,
        "top_requested_drugs_by_area": top_drugs_by_area,
    }


async def get_admin_report_cards(db: AsyncSession, days: int = 7) -> List[dict]:
    """
    Convenience helper for UI cards-only views.
    """
    # Reuse the same generator to avoid card/report drift.
    report = await generate_admin_report(db, days)
    return report["cards"]


async def update_pharmacy_profile(
    db: AsyncSession,
    pharmacy_id: str,
    profile_update: schemas.PharmacyProfileUpdate
) -> Optional[PharmacyNode]:
    """
    Updates the fields of a pharmacy node. If coordinates are provided,
    re-generates the PostGIS location Point.
    """
    db_node = await get_pharmacy_node(db, pharmacy_id)
    if db_node:
        if profile_update.business_name is not None:
            db_node.business_name = profile_update.business_name
        if profile_update.phone_number is not None:
            db_node.phone_number = profile_update.phone_number
        if profile_update.latitude is not None and profile_update.longitude is not None:
            point_wkt = f"POINT({profile_update.longitude} {profile_update.latitude})"
            db_node.location = f"SRID=4326;{point_wkt}"
        db.add(db_node)
        await db.commit()
        await db.refresh(db_node)
    return db_node


async def get_user_relevant_requests(db: AsyncSession, pharmacy_id: str) -> List[StockRequest]:
    """
    Retrieves all stock requests created by the pharmacy OR sent as alerts to the pharmacy.
    """
    stmt = (
        select(StockRequest)
        .outerjoin(AlertNotification, StockRequest.request_id == AlertNotification.request_id)
        .where(
            (StockRequest.pharmacy_id == pharmacy_id) |
            (AlertNotification.receiving_pharmacy_id == pharmacy_id)
        )
        .options(selectinload(StockRequest.alerts), selectinload(StockRequest.pharmacy))
        .distinct()
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_all_user_alerts(db: AsyncSession, pharmacy_id: str) -> List[AlertNotification]:
    """
    Retrieves all alert notifications targeted at the pharmacy.
    """
    stmt = (
        select(AlertNotification)
        .where(AlertNotification.receiving_pharmacy_id == pharmacy_id)
        .options(
            selectinload(AlertNotification.request)
            .selectinload(StockRequest.pharmacy)
        )
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def respond_to_stock_request(
    db: AsyncSession,
    pharmacy_id: str,
    request_id: str,
    status_str: str
) -> Optional[StockRequest]:
    """
    Neighbor responds (ACCEPTED/DECLINED) to a stock request alert.
    Updates the AlertNotification and, if accepted, updates StockRequest status
    and records a TransactionLog.
    """
    stmt = (
        select(AlertNotification)
        .where(AlertNotification.request_id == request_id)
        .where(AlertNotification.receiving_pharmacy_id == pharmacy_id)
    )
    result = await db.execute(stmt)
    alert = result.scalar_one_or_none()
    
    if not alert:
        return None
    
    alert.alert_status = status_str
    db.add(alert)
    
    req_stmt = (
        select(StockRequest)
        .where(StockRequest.request_id == request_id)
        .options(selectinload(StockRequest.alerts), selectinload(StockRequest.pharmacy))
    )
    req_result = await db.execute(req_stmt)
    db_request = req_result.scalar_one_or_none()
    
    if db_request and status_str == "ACCEPTED":
        db_request.request_status = "FULFILLED"
        db.add(db_request)
        
        log = TransactionLog(
            request_id=request_id,
            drug_category=db_request.requested_drug,
            final_outcome="FULFILLED_BY_NEIGHBOR"
        )
        db.add(log)
        
    await db.commit()
    if db_request:
        # Re-query after commit to load alerts relationship and prevent expired lazy-load errors
        refetch_stmt = (
            select(StockRequest)
            .where(StockRequest.request_id == request_id)
            .options(selectinload(StockRequest.alerts), selectinload(StockRequest.pharmacy))
        )
        refetch_result = await db.execute(refetch_stmt)
        db_request = refetch_result.scalar_one_or_none()
    return db_request



async def get_last_sent_request(db: AsyncSession, pharmacy_id: str) -> Optional[StockRequest]:
    """
    Retrieves the most recent stock request created by the pharmacy.
    """
    stmt = (
        select(StockRequest)
        .where(StockRequest.pharmacy_id == pharmacy_id)
        .order_by(StockRequest.created_at.desc())
        .options(selectinload(StockRequest.pharmacy), selectinload(StockRequest.alerts))
        .limit(1)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


def _serialize_request_with_responder(
    request: StockRequest,
    accepted_by_pharmacy: dict | None,
    accepted_at,
) -> dict:
    return {
        "request_id": request.request_id,
        "pharmacy_id": request.pharmacy_id,
        "requested_drug": request.requested_drug,
        "required_quantity": request.required_quantity,
        "search_radius_meters": request.search_radius_meters,
        "request_status": request.request_status,
        "created_at": request.created_at,
        "alerts": [
            {
                "alert_id": alert.alert_id,
                "request_id": alert.request_id,
                "receiving_pharmacy_id": alert.receiving_pharmacy_id,
                "alert_status": alert.alert_status,
                "delivered_at": alert.delivered_at,
            }
            for alert in request.alerts
        ],
        "pharmacy": {
            "pharmacy_id": request.pharmacy.pharmacy_id,
            "business_name": request.pharmacy.business_name,
            "email": request.pharmacy.email,
            "phone_number": request.pharmacy.phone_number,
        }
        if request.pharmacy
        else None,
        "accepted_by_pharmacy": accepted_by_pharmacy,
        "accepted_at": accepted_at,
    }


async def get_last_sent_request_with_responder(
    db: AsyncSession,
    pharmacy_id: str,
) -> Optional[dict]:
    """
    Retrieves the most recent sent request and enriches it with the accepting
    pharmacy details when available.
    """
    request = await get_last_sent_request(db, pharmacy_id)
    if not request:
        return None

    accepted_stmt = (
        select(AlertNotification, PharmacyNode)
        .join(
            PharmacyNode,
            PharmacyNode.pharmacy_id == AlertNotification.receiving_pharmacy_id,
        )
        .where(AlertNotification.request_id == request.request_id)
        .where(AlertNotification.alert_status == "ACCEPTED")
        .order_by(AlertNotification.delivered_at.desc())
        .limit(1)
    )
    accepted_result = await db.execute(accepted_stmt)
    accepted_row = accepted_result.first()

    accepted_by_pharmacy = None
    accepted_at = None
    if accepted_row:
        accepted_alert, responder = accepted_row
        accepted_by_pharmacy = {
            "pharmacy_id": responder.pharmacy_id,
            "business_name": responder.business_name,
            "email": responder.email,
            "phone_number": responder.phone_number,
        }
        accepted_at = accepted_alert.delivered_at

    return _serialize_request_with_responder(
        request,
        accepted_by_pharmacy,
        accepted_at,
    )


async def get_sent_requests_with_responder(
    db: AsyncSession,
    pharmacy_id: str,
) -> List[dict]:
    """
    Retrieves all sent requests and enriches each with accepting pharmacy details
    when available.
    """
    stmt = (
        select(StockRequest)
        .where(StockRequest.pharmacy_id == pharmacy_id)
        .order_by(StockRequest.created_at.desc())
        .options(selectinload(StockRequest.pharmacy), selectinload(StockRequest.alerts))
    )
    result = await db.execute(stmt)
    requests = list(result.scalars().all())

    sent_requests = []
    for request in requests:
        accepted_stmt = (
            select(AlertNotification, PharmacyNode)
            .join(
                PharmacyNode,
                PharmacyNode.pharmacy_id == AlertNotification.receiving_pharmacy_id,
            )
            .where(AlertNotification.request_id == request.request_id)
            .where(AlertNotification.alert_status == "ACCEPTED")
            .order_by(AlertNotification.delivered_at.desc())
            .limit(1)
        )
        accepted_result = await db.execute(accepted_stmt)
        accepted_row = accepted_result.first()

        accepted_by_pharmacy = None
        accepted_at = None
        if accepted_row:
            accepted_alert, responder = accepted_row
            accepted_by_pharmacy = {
                "pharmacy_id": responder.pharmacy_id,
                "business_name": responder.business_name,
                "email": responder.email,
                "phone_number": responder.phone_number,
            }
            accepted_at = accepted_alert.delivered_at

        sent_requests.append(
            _serialize_request_with_responder(
                request,
                accepted_by_pharmacy,
                accepted_at,
            )
        )

    return sent_requests


async def get_last_accepted_request(db: AsyncSession, pharmacy_id: str) -> Optional[StockRequest]:
    """
    Retrieves the most recent stock request accepted by the pharmacy.
    """
    stmt = (
        select(StockRequest)
        .join(AlertNotification, StockRequest.request_id == AlertNotification.request_id)
        .where(AlertNotification.receiving_pharmacy_id == pharmacy_id)
        .where(AlertNotification.alert_status == "ACCEPTED")
        .order_by(AlertNotification.delivered_at.desc())
        .options(selectinload(StockRequest.pharmacy))
        .limit(1)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()



async def get_dashboard_metrics(db: AsyncSession, pharmacy_id: str) -> dict:
    """
    Consolidates stats, recent requests, active queries, and low stock items.
    """
    # Count PENDING requests created by the user
    active_queries_stmt = select(func.count(StockRequest.request_id)).where(
        StockRequest.pharmacy_id == pharmacy_id,
        StockRequest.request_status == "PENDING"
    )
    active_queries_count = (await db.execute(active_queries_stmt)).scalar() or 0
    
    # Count all alert notifications received by the user
    received_stmt = select(func.count(AlertNotification.alert_id)).where(
        AlertNotification.receiving_pharmacy_id == pharmacy_id
    )
    received_count = (await db.execute(received_stmt)).scalar() or 0
    
    # Count FULFILLED requests created by the user
    completed_stmt = select(func.count(StockRequest.request_id)).where(
        StockRequest.pharmacy_id == pharmacy_id,
        StockRequest.request_status == "FULFILLED"
    )
    completed_count = (await db.execute(completed_stmt)).scalar() or 0
    
    # Recent received requests (last 5 alerts received)
    alerts_stmt = (
        select(AlertNotification)
        .where(AlertNotification.receiving_pharmacy_id == pharmacy_id)
        .options(
            selectinload(AlertNotification.request)
            .selectinload(StockRequest.pharmacy)
        )
        .order_by(AlertNotification.delivered_at.desc())
        .limit(5)
    )
    alerts_result = await db.execute(alerts_stmt)
    recent_alerts = alerts_result.scalars().all()
    
    recent_requests = []
    for alert in recent_alerts:
        if alert.request:
            recent_requests.append({
                "drug_name": alert.request.requested_drug,
                "source": alert.request.pharmacy.business_name if alert.request.pharmacy else "Unknown",
                "created_at": alert.delivered_at,
                "status": alert.alert_status
            })
    
    # My active queries (pending requests created by the user)
    queries_stmt = (
        select(StockRequest)
        .where(
            StockRequest.pharmacy_id == pharmacy_id,
            StockRequest.request_status == "PENDING"
        )
        .order_by(StockRequest.created_at.desc())
    )
    queries_result = await db.execute(queries_stmt)
    active_queries_db = queries_result.scalars().all()
    
    active_queries = []
    for req in active_queries_db:
        active_queries.append({
            "drug_name": req.requested_drug,
            "meta": f"{req.required_quantity} units · {req.search_radius_meters}m radius",
            "status": req.request_status
        })
    
    # Low stock items (inventory items with stock_quantity <= 10)
    low_stock_stmt = (
        select(InventoryItem)
        .where(
            InventoryItem.pharmacy_id == pharmacy_id,
            InventoryItem.stock_quantity <= 10
        )
        .order_by(InventoryItem.stock_quantity.asc())
    )
    low_stock_result = await db.execute(low_stock_stmt)
    low_stock_items = list(low_stock_result.scalars().all())
    
    return {
        "stats": {
            "active_queries": active_queries_count,
            "requests_received": received_count,
            "completed": completed_count
        },
        "recent_requests": recent_requests,
        "active_queries": active_queries,
        "low_stock_items": low_stock_items
    }


async def get_user_transaction_history(db: AsyncSession, pharmacy_id: str) -> List[dict]:
    """
    Retrieves transactions relevant to a pharmacy (as requester or accepted responder).
    """
    from sqlalchemy.orm import aliased

    RequesterPharmacy = aliased(PharmacyNode)
    ResponderPharmacy = aliased(PharmacyNode)

    stmt = (
        select(
            TransactionLog.log_id.label("id"),
            TransactionLog.final_outcome.label("outcome"),
            TransactionLog.resolved_at.label("resolved_at"),
            StockRequest.requested_drug.label("drug"),
            RequesterPharmacy.pharmacy_id.label("requester_id"),
            RequesterPharmacy.business_name.label("requester_name"),
            ResponderPharmacy.pharmacy_id.label("responder_id"),
            ResponderPharmacy.business_name.label("responder_name"),
        )
        .join(StockRequest, TransactionLog.request_id == StockRequest.request_id)
        .join(
            RequesterPharmacy,
            StockRequest.pharmacy_id == RequesterPharmacy.pharmacy_id,
        )
        .outerjoin(
            AlertNotification,
            (StockRequest.request_id == AlertNotification.request_id)
            & (AlertNotification.alert_status == "ACCEPTED"),
        )
        .outerjoin(
            ResponderPharmacy,
            AlertNotification.receiving_pharmacy_id == ResponderPharmacy.pharmacy_id,
        )
        .where(
            (RequesterPharmacy.pharmacy_id == pharmacy_id)
            | (ResponderPharmacy.pharmacy_id == pharmacy_id)
        )
        .order_by(TransactionLog.resolved_at.desc())
    )

    result = await db.execute(stmt)
    rows = result.all()

    transactions = []
    for row in rows:
        if row.requester_id == pharmacy_id:
            counterparty = row.responder_name or "Neighbor Pharmacy"
        else:
            counterparty = row.requester_name or "Unknown pharmacy"

        transactions.append({
            "id": row.id,
            "drug": row.drug,
            "pharmacy": counterparty,
            "counterparty": counterparty,
            "status": "completed"
            if row.outcome == "FULFILLED_BY_NEIGHBOR"
            else row.outcome,
            "date": row.resolved_at.isoformat() if row.resolved_at else "-",
            "created_at": row.resolved_at.isoformat() if row.resolved_at else "-",
        })

    return transactions


async def get_system_transactions(db: AsyncSession) -> List[dict]:
    """
    Retrieves system-wide transactions formatted for the admin transaction monitor.
    """
    from sqlalchemy.orm import aliased
    ResponderPharmacy = aliased(PharmacyNode)
    
    stmt = (
        select(
            TransactionLog.log_id.label("id"),
            TransactionLog.final_outcome.label("outcome"),
            StockRequest.requested_drug.label("drug"),
            PharmacyNode.business_name.label("receiver"),
            ResponderPharmacy.business_name.label("sender")
        )
        .join(StockRequest, TransactionLog.request_id == StockRequest.request_id)
        .join(PharmacyNode, StockRequest.pharmacy_id == PharmacyNode.pharmacy_id)
        .outerjoin(AlertNotification, (StockRequest.request_id == AlertNotification.request_id) & (AlertNotification.alert_status == "ACCEPTED"))
        .outerjoin(ResponderPharmacy, AlertNotification.receiving_pharmacy_id == ResponderPharmacy.pharmacy_id)
        .order_by(TransactionLog.resolved_at.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()
    
    txns = []
    for row in rows:
        txns.append({
            "id": row.id,
            "from": row.sender if row.sender else "Neighbor Pharmacy",
            "to": row.receiver,
            "drug": row.drug,
            "status": "completed" if row.outcome == "FULFILLED_BY_NEIGHBOR" else row.outcome
        })
    return txns


async def get_system_audit_logs(db: AsyncSession) -> List[dict]:
    """
    Dynamically compiles system events (registration, admin setup, transactions)
    into a unified chronological audit log.
    """
    # Query pharmacy nodes registrations
    stmt_nodes = select(PharmacyNode.business_name, PharmacyNode.created_at).order_by(PharmacyNode.created_at.desc())
    nodes = (await db.execute(stmt_nodes)).all()
    
    # Query transaction outcomes
    stmt_tx = (
        select(StockRequest.requested_drug, TransactionLog.resolved_at)
        .join(StockRequest, TransactionLog.request_id == StockRequest.request_id)
        .order_by(TransactionLog.resolved_at.desc())
    )
    txs = (await db.execute(stmt_tx)).all()
    
    # Query system admins
    stmt_admins = select(SystemAdmin.email, SystemAdmin.created_at).order_by(SystemAdmin.created_at.desc())
    admins = (await db.execute(stmt_admins)).all()
    
    logs = []
    for n in nodes:
        logs.append({
            "action": f"Pharmacy Registered: {n.business_name}",
            "user": "System Gateway",
            "time": n.created_at
        })
    for t in txs:
        logs.append({
            "action": f"Stock Request Resolved: {t.requested_drug}",
            "user": "Routing Engine",
            "time": t.resolved_at
        })
    for a in admins:
        logs.append({
            "action": f"Admin Enrolled: {a.email}",
            "user": "Supabase Auth Broker",
            "time": a.created_at
        })
        
    # Sort logs descending by time
    logs.sort(key=lambda x: x["time"], reverse=True)
    return logs


async def review_onboarding_pharmacy(
    db: AsyncSession,
    pharmacy_id: str,
    approved: bool
) -> Optional[PharmacyNode]:
    """
    Sets account status to ACTIVE if approved is True, otherwise REJECTED.
    """
    db_node = await get_pharmacy_node(db, pharmacy_id)
    if db_node:
        db_node.account_status = "ACTIVE" if approved else "REJECTED"
        db.add(db_node)
        await db.commit()
        await db.refresh(db_node)
    return db_node