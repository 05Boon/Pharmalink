from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func
from sqlalchemy.future import select

from app.database import get_db
from app.dependencies import get_current_user_uuid
from app.models import PharmacyNode
from app import crud
from app import schemas

auth_router = APIRouter()

@auth_router.post(
    "/pharmacies/sync-profile",
    response_model=schemas.PharmacyNodeResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Synchronize pharmacy profile info with Supabase authenticated UUID"
)
async def sync_profile(
    profile: schemas.PharmacyProfileSync,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Synchronizes profile information. Expects a Supabase Auth JWT.
    Extracts the authenticated UUID from the token, checks for duplicates,
    and inserts the pharmacy node using the UUID as primary key.
    """
    # 1. Check if a pharmacy node with this UUID already exists
    existing_node = await crud.get_pharmacy_node(db, pharmacy_id)
    if existing_node:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pharmacy profile is already synchronized."
        )

    # 2. Check for unique constraints duplicate (license_number)
    duplicate_license = await crud.get_pharmacy_node_by_license(db, profile.license_number)
    if duplicate_license:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pharmacy with this license number is already registered."
        )

    # 3. Check for unique constraints duplicate (email)
    duplicate_email = await crud.get_pharmacy_node_by_email(db, profile.email)
    if duplicate_email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A pharmacy with this email is already registered."
        )

    # 4. Insert the node
    db_node = await crud.create_pharmacy_node(db, pharmacy_id, profile)

    return schemas.PharmacyNodeResponse(
        pharmacy_id=db_node.pharmacy_id,
        business_name=db_node.business_name,
        license_number=db_node.license_number,
        email=db_node.email,
        phone_number=db_node.phone_number,
        latitude=profile.latitude,
        longitude=profile.longitude,
        account_status=db_node.account_status,
        created_at=db_node.created_at
    )


@auth_router.get(
    "/pharmacies/me",
    response_model=schemas.PharmacyNodeResponse,
    summary="Get authenticated pharmacy's profile details"
)
async def get_my_profile(
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns the authenticated pharmacy owner's profile details.
    """
    node = await crud.get_pharmacy_node(db, pharmacy_id)
    if not node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy profile not found."
        )
    
    # Extract coordinates
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
        account_status=node.account_status,
        created_at=node.created_at
    )


@auth_router.put(
    "/pharmacies/me",
    response_model=schemas.PharmacyNodeResponse,
    summary="Update authenticated pharmacy's profile details"
)
async def update_my_profile(
    profile_update: schemas.PharmacyProfileUpdate,
    pharmacy_id: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
):
    """
    Updates the authenticated pharmacy owner's profile details.
    """
    updated_node = await crud.update_pharmacy_profile(db, pharmacy_id, profile_update)
    if not updated_node:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pharmacy profile not found."
        )
    
    # Extract coordinates
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

