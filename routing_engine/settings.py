import os

try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - fallback when python-dotenv is absent.
    def load_dotenv() -> bool:
        return False

# Load local .env automatically for backend processes.
load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://admin:local_secret_password@localhost:5433/pharmacy_network_db",
)

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
