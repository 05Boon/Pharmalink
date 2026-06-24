import base64
import json
from fastapi import Header, HTTPException, status
from typing import Optional

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

def get_current_user_uuid(authorization: str = Header(...)) -> str:
    """
    FastAPI dependency that extracts and validates the current user's UUID.
    Expects a Bearer token in the Authorization header.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization format. Must start with 'Bearer '."
        )
    token = authorization.split(" ")[1]
    user_uuid = resolve_token(token)
    if not user_uuid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication credentials."
        )
    return user_uuid
