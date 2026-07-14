from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
from sqlalchemy.future import select
import datetime

from app.database import get_db
from app.dependencies import get_current_admin
from app.models import PharmacyNode
from app import crud
from app import schemas

admin_router = APIRouter(prefix="/admin", tags=["admin"])


def _csv_escape(value) -> str:
    text = "" if value is None else str(value)
    return '"' + text.replace('"', '""') + '"'


@admin_router.get(
    "/pharmacies",
    response_model=list[schemas.PharmacyNodeResponse],
    summary="List all pharmacy nodes (Admin only)"
)
async def get_all_pharmacies(
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns a list of all registered pharmacy nodes with their locations.
    Only accessible by administrators.
    """
    # Admin governance flow: list all registered pharmacy nodes with map coordinates.
    stmt = select(PharmacyNode)
    result = await db.execute(stmt)
    nodes = result.scalars().all()
    
    response_nodes = []
    for node in nodes:
        # Extract coordinates
        coord_query = select(
            func.ST_X(PharmacyNode.location),
            func.ST_Y(PharmacyNode.location)
        ).where(PharmacyNode.pharmacy_id == node.pharmacy_id)
        coord_result = await db.execute(coord_query)
        coord = coord_result.first()
        
        longitude = coord[0] if coord else 0.0
        latitude = coord[1] if coord else 0.0
        response_nodes.append(schemas.PharmacyNodeResponse(
            pharmacy_id=node.pharmacy_id,
            business_name=node.business_name,
            license_number=node.license_number,
            email=node.email,
            phone_number=node.phone_number,
            latitude=latitude,
            longitude=longitude,
            general_location=node.general_location,
            account_status=node.account_status,
            created_at=node.created_at
        ))
    return response_nodes


@admin_router.patch(
    "/pharmacies/{pharmacy_id}/status",
    response_model=schemas.PharmacyNodeResponse,
    summary="Update the account status of a pharmacy node (Admin only)"
)
async def patch_pharmacy_status(
    pharmacy_id: str,
    status_update: schemas.PharmacyStatusUpdate,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Toggles/updates a pharmacy's account status (e.g. ACTIVE vs SUSPENDED).
    Requires a valid admin JWT. Returns the updated pharmacy profile.
    """
    # Admin lifecycle control: activate/suspend nodes.
    updated_node = await crud.update_pharmacy_status(db, pharmacy_id, status_update.account_status)
    if not updated_node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy node not found."
        )

    # Query the database to extract the latitude and longitude from the geometry point
    coord_query = select(
        func.ST_X(PharmacyNode.location),
        func.ST_Y(PharmacyNode.location)
    ).where(PharmacyNode.pharmacy_id == pharmacy_id)
    coord_result = await db.execute(coord_query)
    coord = coord_result.first()

    longitude = coord[0] if coord else 0.0
    latitude = coord[1] if coord else 0.0

    return schemas.PharmacyNodeResponse(
        pharmacy_id=updated_node.pharmacy_id,
        business_name=updated_node.business_name,
        license_number=updated_node.license_number,
        email=updated_node.email,
        phone_number=updated_node.phone_number,
        latitude=latitude,
        longitude=longitude,
        general_location=updated_node.general_location,
        account_status=updated_node.account_status,
        created_at=updated_node.created_at
    )


@admin_router.get(
    "/analytics/outbreaks",
    response_model=list[schemas.OutbreakAnalytic],
    summary="Retrieve geospatial outbreak detection analytics based on recent stock requests"
)
async def get_outbreaks(
    days: int = 7,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieves geospatial outbreak detection analytics (grouped by drug, average coordinates as centroids, and request frequency).
    Only accessible by administrators.
    """
    # Admin analytics flow: geospatial outbreak clustering by timeframe.
    if days <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Days parameter must be a positive integer."
        )
    return await crud.get_outbreaks_analytics(db, days)


@admin_router.get(
    "/pharmacies/{pharmacy_id}",
    response_model=schemas.PharmacyNodeResponse,
    summary="Get details of a specific pharmacy node (Admin only)"
)
async def get_pharmacy_detail(
    pharmacy_id: str,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    node = await crud.get_pharmacy_node(db, pharmacy_id)
    if not node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy node not found."
        )
    
    # Query coordinates
    coord_query = select(
        func.ST_X(PharmacyNode.location),
        func.ST_Y(PharmacyNode.location)
    ).where(PharmacyNode.pharmacy_id == pharmacy_id)
    coord_result = await db.execute(coord_query)
    coord = coord_result.first()
    
    longitude = coord[0] if coord else 0.0
    latitude = coord[1] if coord else 0.0
    
    return schemas.PharmacyNodeResponse(
        pharmacy_id=node.pharmacy_id,
        business_name=node.business_name,
        license_number=node.license_number,
        email=node.email,
        phone_number=node.phone_number,
        latitude=latitude,
        longitude=longitude,
        general_location=node.general_location,
        account_status=node.account_status,
        created_at=node.created_at
    )


@admin_router.get(
    "/pharmacies/{pharmacy_id}/inventory",
    response_model=list[schemas.InventoryItemResponse],
    summary="Get inventory items of a specific pharmacy node (Admin only)"
)
async def get_pharmacy_inventory(
    pharmacy_id: str,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    # Verify node exists
    node = await crud.get_pharmacy_node(db, pharmacy_id)
    if not node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy node not found."
        )
    return await crud.get_inventory_items(db, pharmacy_id)


@admin_router.delete(
    "/pharmacies/{pharmacy_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a pharmacy node (Admin only)"
)
async def delete_pharmacy(
    pharmacy_id: str,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Permanently deletes a pharmacy node from the network.
    """
    # Admin destructive operation guarded by status rules.
    node = await crud.get_pharmacy_node(db, pharmacy_id)
    if not node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy node not found."
        )

    if (node.account_status or "").upper() == "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Suspend the pharmacy before deleting it."
        )

    deleted = await crud.delete_pharmacy_node(db, pharmacy_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy node not found."
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@admin_router.patch(
    "/pharmacies/{pharmacy_id}/onboarding",
    response_model=schemas.PharmacyNodeResponse,
    summary="Submit onboarding approval review for a pharmacy node (Admin only)"
)
async def patch_onboarding_status(
    pharmacy_id: str,
    payload: schemas.OnboardingReviewInput,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    updated_node = await crud.review_onboarding_pharmacy(db, pharmacy_id, payload.approved)
    if not updated_node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy node not found."
        )
    
    # Query coordinates
    coord_query = select(
        func.ST_X(PharmacyNode.location),
        func.ST_Y(PharmacyNode.location)
    ).where(PharmacyNode.pharmacy_id == pharmacy_id)
    coord_result = await db.execute(coord_query)
    coord = coord_result.first()
    
    longitude = coord[0] if coord else 0.0
    latitude = coord[1] if coord else 0.0
    
    return schemas.PharmacyNodeResponse(
        pharmacy_id=updated_node.pharmacy_id,
        business_name=updated_node.business_name,
        license_number=updated_node.license_number,
        email=updated_node.email,
        phone_number=updated_node.phone_number,
        latitude=latitude,
        longitude=longitude,
        account_status=updated_node.account_status,
        created_at=updated_node.created_at
    )


@admin_router.get(
    "/transactions",
    response_model=list[schemas.AdminTransactionResponse],
    summary="Monitor system-wide transaction history logs (Admin only)"
)
async def get_transactions_history(
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await crud.get_system_transactions(db)


@admin_router.get(
    "/logs",
    response_model=list[schemas.AdminAuditLogResponse],
    summary="Retrieve system-wide audit event logs (Admin only)"
)
async def get_audit_logs(
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    return await crud.get_system_audit_logs(db)


@admin_router.get(
    "/reports",
    response_model=list[schemas.AdminReportCard],
    summary="Get report cards for admin reporting view"
)
async def get_report_cards(
    days: int = 7,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns a lightweight card-only report payload for compact dashboard views.
    """
    if days <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Days parameter must be a positive integer."
        )
    # Lightweight endpoint for quick cards rendering.
    return await crud.get_admin_report_cards(db, days)


@admin_router.post(
    "/reports/generate",
    response_model=schemas.AdminGeneratedReport,
    summary="Generate an admin operations report snapshot"
)
async def generate_admin_report(
    days: int = 7,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Generates a full admin report including summary cards and top requested drugs.
    """
    if days <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Days parameter must be a positive integer."
        )
    # Full report payload used for detailed admin analysis views.
    return await crud.generate_admin_report(db, days)


@admin_router.get(
    "/reports/export",
    summary="Export generated admin report as CSV"
)
async def export_admin_report_csv(
    days: int = 7,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Exports the same generated report data in CSV format for download.
    """
    if days <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Days parameter must be a positive integer."
        )

    report = await crud.generate_admin_report(db, days)
    generated_at = report.get("generated_at")
    generated_at_text = generated_at.isoformat() if generated_at else ""

    lines = [
        "section,key,value",
        f"summary,{_csv_escape('generated_at')},{_csv_escape(generated_at_text)}",
        f"summary,{_csv_escape('timeframe_days')},{_csv_escape(report.get('timeframe_days', days))}",
        "",
        "cards,title,description,icon",
    ]

    for card in report.get("cards", []):
        lines.append(
            "cards,"
            f"{_csv_escape(card.get('title', ''))},"
            f"{_csv_escape(card.get('description', ''))},"
            f"{_csv_escape(card.get('icon', ''))}"
        )

    lines.append("")
    lines.append("top_requested_drugs,drug_name,request_count")
    for item in report.get("top_requested_drugs", []):
        lines.append(
            "top_requested_drugs,"
            f"{_csv_escape(item.get('drug_name', ''))},"
            f"{_csv_escape(item.get('request_count', 0))}"
        )

    lines.append("")
    lines.append(
        "top_requested_drugs_by_area,area_label,area_latitude,area_longitude,top_drug,request_count,total_requests_in_area"
    )
    for item in report.get("top_requested_drugs_by_area", []):
        lines.append(
            "top_requested_drugs_by_area,"
            f"{_csv_escape(item.get('area_label', ''))},"
            f"{_csv_escape(item.get('area_latitude', 0.0))},"
            f"{_csv_escape(item.get('area_longitude', 0.0))},"
            f"{_csv_escape(item.get('top_drug', ''))},"
            f"{_csv_escape(item.get('request_count', 0))},"
            f"{_csv_escape(item.get('total_requests_in_area', 0))}"
        )

    csv_text = "\n".join(lines)
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"admin_report_{days}d_{timestamp}.csv"
    return Response(
        content=csv_text,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@admin_router.get(
    "/outbreak-alerts",
    response_model=list[schemas.OutbreakAlert],
    summary="Detect localized outbreak clusters"
)
async def get_outbreak_alerts(
    days_back: int = 7,
    threshold: int = 2,
    admin=Depends(get_current_admin),
    db: AsyncSession = Depends(get_db)
):
    """
    Analyzes recent stock requests using pure SQL to detect localized
    clusters of specific shortages.
    """
    alerts = await crud.detect_outbreaks(db, days_back=days_back, threshold=threshold)
    return alerts
