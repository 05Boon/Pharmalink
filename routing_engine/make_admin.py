"""
One-off script: grants admin privileges to an existing Supabase Auth user
by inserting a row into the system_admins table.

This is intentionally NOT exposed as a Flutter UI or backend API endpoint.
Granting admin access is a sensitive, infrequent action — handling it as a
script you run locally (rather than a button shipped in the client app)
avoids exposing any privilege-escalation path to end users.

PREREQUISITE: the person must already have a normal Supabase Auth account
(e.g. they registered as a pharmacy through the app, or you created an
account for them directly in Supabase Auth). This script does NOT create
a new auth user — it only grants admin rights to one that already exists,
identified by their Supabase Auth UUID.

Usage:
    python make_admin.py <supabase_auth_uuid> <email> [role_level]

Example:
    python make_admin.py 3fa2c1e0-... derrick@pharmalink.dev 1

To find a user's Supabase Auth UUID:
    Supabase dashboard -> Authentication -> Users -> click the user
    -> copy the "User UID" field.
"""
import asyncio
import sys
import uuid as uuid_module

from sqlalchemy import select
from database import AsyncSessionLocal
from models import SystemAdmin


async def make_admin(admin_uuid: str, email: str, role_level: int = 1):
    # Sanity-check the UUID format before writing anything — a typo'd
    # UUID here would silently create an admin row that never matches
    # any real authenticated user, since get_current_admin matches by
    # exact admin_id == the UUID from the validated Supabase JWT.
    try:
        uuid_module.UUID(admin_uuid)
    except ValueError:
        print(
            f"'{admin_uuid}' doesn't look like a valid UUID. "
            "Copy the exact 'User UID' from Supabase dashboard -> "
            "Authentication -> Users."
        )
        return

    async with AsyncSessionLocal() as db:
        existing = await db.execute(
            select(SystemAdmin).where(SystemAdmin.admin_id == admin_uuid)
        )
        if existing.scalar_one_or_none():
            print(f"{email} ({admin_uuid}) is already an admin. Nothing to do.")
            return

        admin = SystemAdmin(
            admin_id=admin_uuid,
            email=email,
            role_level=role_level,
        )
        db.add(admin)
        await db.commit()

    print(f"Granted admin access to {email} ({admin_uuid}), role_level={role_level}.")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python make_admin.py <supabase_auth_uuid> <email> [role_level]")
        sys.exit(1)

    admin_uuid_arg = sys.argv[1]
    email_arg = sys.argv[2]
    role_level_arg = int(sys.argv[3]) if len(sys.argv) > 3 else 1

    asyncio.run(make_admin(admin_uuid_arg, email_arg, role_level_arg))