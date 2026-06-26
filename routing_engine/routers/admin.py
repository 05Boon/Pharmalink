from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
from sqlalchemy.future import select

from database import get_db
from dependencies import get_current_admin
from models import PharmacyNode
import crud
import schemas

admin_router = APIRouter(prefix="/api/admin", tags=["admin"])

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
        account_status=updated_node.account_status,
        created_at=updated_node.created_at
    )
