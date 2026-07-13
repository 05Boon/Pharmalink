from fastapi import Header, HTTPException, status, Depends
from typing import Optional
from httpx import AsyncClient
from app.settings import ALLOW_MOCK_AUTH, SUPABASE_ANON_KEY, SUPABASE_URL, MOCK_AUTH_BYPASS, MOCK_PHARMACY_UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database import get_db
from app.models import SystemAdmin

async def resolve_token(token: str) -> Optional[str]:
    """
    Resolves a token into a user UUID strictly via Supabase validation.
    Mock tokens are accepted only when ALLOW_MOCK_AUTH is enabled.
    """
    if MOCK_AUTH_BYPASS:
        return MOCK_PHARMACY_UUID

    if not token:
        return None

    user_info = await _validate_supabase_jwt(token)
    if not user_info or not user_info.get("id"):
        return None
    return str(user_info["id"])

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
    if token.startswith("mock-") and ALLOW_MOCK_AUTH:
        return {"id": token, "email": None}

    if token.startswith("mock-") and not ALLOW_MOCK_AUTH:
        return None

    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        print(f"[AUTH DEBUG] Missing config — SUPABASE_URL={SUPABASE_URL!r} ANON_KEY_SET={bool(SUPABASE_ANON_KEY)}")
        return None

    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {token}",
    }

    print(f"[AUTH DEBUG] Validating against {SUPABASE_URL}/auth/v1/user — token prefix: {token[:15]}...")

    try:
        async with AsyncClient(timeout=10.0) as client:
            response = await client.get(f"{SUPABASE_URL}/auth/v1/user", headers=headers)
    except Exception as e:
        print(f"[AUTH DEBUG] Request exception: {type(e).__name__}: {e}")
        return None

    if response.status_code < 200 or response.status_code >= 300:
        print(f"[AUTH DEBUG] Supabase returned {response.status_code}: {response.text[:300]}")
        return None

    try:
        payload = response.json()
    except Exception as e:
        print(f"[AUTH DEBUG] Failed to parse JSON response: {e}")
        return None

    if isinstance(payload, dict) and payload.get("id"):
        print(f"[AUTH DEBUG] Validated successfully, user id: {payload.get('id')}")
        return payload
    print(f"[AUTH DEBUG] Payload missing id field: {payload}")
    return None


async def get_current_user_uuid(authorization: Optional[str] = Header(None)) -> str:
    """
    FastAPI dependency that validates a Supabase JWT and returns user UUID.
    """
    if MOCK_AUTH_BYPASS:
        return MOCK_PHARMACY_UUID

    token = parse_bearer_token(authorization)
    user_uuid = await resolve_token(token)
    if not user_uuid:
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
    if MOCK_AUTH_BYPASS:
        return SystemAdmin(admin_id="mock-admin", email="admin@local.test")

    stmt = select(SystemAdmin).where(SystemAdmin.admin_id == admin_uuid)
    result = await db.execute(stmt)
    admin = result.scalar_one_or_none()
    
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden. Admin privilege required."
        )
    return admin