import os

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - fallback when python-dotenv is absent.
    def load_dotenv() -> bool:
        return False

# Load local .env automatically for backend processes.
load_dotenv()


def _to_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://admin:local_secret_password@localhost:5432/pharmacy_network_db",
)

SUPABASE_URL = os.getenv("SUPABASE_URL")
if SUPABASE_URL:
    SUPABASE_URL = SUPABASE_URL.rstrip("/")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

APP_ENV = os.getenv("APP_ENV", "development").strip().lower()
# Allow mock auth only in non-production unless explicitly overridden.
ALLOW_MOCK_AUTH = _to_bool(
    os.getenv("ALLOW_MOCK_AUTH"),
    default=APP_ENV != "production",
)

MOCK_AUTH_BYPASS = _to_bool(
    os.getenv("MOCK_AUTH_BYPASS"),
    default=False,
)
MOCK_PHARMACY_UUID = os.getenv("MOCK_PHARMACY_UUID", "00000000-0000-0000-0000-000000000000")

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://admin:local_secret_password@localhost:5432/pharmacy_network_db",
)

# Fail fast in production if required Supabase credentials are missing
if APP_ENV == "production" and (not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY):
    raise RuntimeError(
        "CRITICAL ERROR: Production environment (APP_ENV=production) requires "
        "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY to be set in environment variables."
    )

