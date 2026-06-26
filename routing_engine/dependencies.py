import base64
import json
from fastapi import Header, HTTPException, status, Depends
from typing import Optional
from settings import SUPABASE_ANON_KEY, SUPABASE_URL
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from database import get_db
from models import SystemAdmin

def resolve_token(token: str) -> Optional[str]:
    """
    Resolves the provided token and returns the pharmacy/user UUID string.
    Supports a 'mock-' prefixed UUID for local dev/testing, or manual decoding
    of the JWT payload fallback without verifying live signatures.
    """
    if not token:
        return None
    
    # 1. Dev/Testing local override: If it starts with "mock-", return it directly
    if token.startswith("mock-"):
        return token
        
    # 2. Production/Supabase JWT fallback (manual base64 decode of 'sub' claim)
    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        payload_b64 = parts[1]
        # Pad base64 string
        payload_b64 += "=" * ((4 - len(payload_b64) % 4) % 4)
        payload_json = base64.b64decode(payload_b64).decode("utf-8")
        payload = json.loads(payload_json)
        # Supabase stores authenticated user ID in the 'sub' claim
        return payload.get("sub")
    except Exception:
        return None

def parse_bearer_token(authorization: Optional[str]) -> str:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header.",
        )
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization format. Must start with 'Bearer '.",
        )
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication credentials.",
        )
    return token


async def _validate_supabase_jwt(token: str) -> Optional[dict]:
    if token.startswith("mock-"):
        return {"id": token, "email": None}

    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        return None

    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {token}",
    }

    try:
        async with AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{SUPABASE_URL}/auth/v1/user", headers=headers)
    except Exception:
        return None

    if response.status_code < 200 or response.status_code >= 300:
        return None

    try:
        payload = response.json()
    except Exception:
        return None

    if isinstance(payload, dict) and payload.get("id"):
        return payload
    return None


async def get_current_user_uuid(authorization: Optional[str] = Header(None)) -> str:
    """
    FastAPI dependency that validates a Supabase JWT and returns user UUID.
    """
    token = parse_bearer_token(authorization)
    user_info = await _validate_supabase_jwt(token)
    if not user_info:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication credentials.",
        )
    return user_uuid


async def get_current_admin(
    admin_uuid: str = Depends(get_current_user_uuid),
    db: AsyncSession = Depends(get_db)
) -> SystemAdmin:
    """
    FastAPI dependency that extracts the authenticated user UUID and verifies
    that they exist in the SystemAdmin registry database table.
    """
    stmt = select(SystemAdmin).where(SystemAdmin.admin_id == admin_uuid)
    result = await db.execute(stmt)
    admin = result.scalar_one_or_none()
    
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden. Admin privilege required."
        )
    return admin
