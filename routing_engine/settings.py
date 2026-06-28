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
    "postgresql+asyncpg://postgres.fjnbnbtjsuxumtmhcidh:local_secret_password@aws-0-eu-west-1.pooler.supabase.com:5432/postgres",
)

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://fjnbnbtjsuxumtmhcidh.supabase.co").rstrip("/")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqbmJuYnRqc3V4dW10bWhjaWRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjgzNTMsImV4cCI6MjA5NzIwNDM1M30.Ggqrad3PqQ_szto9zgT_alJveag97IgOh_LRB5czC3c")
SUPABASE_SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqbmJuYnRqc3V4dW10bWhjaWRoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTYyODM1MywiZXhwIjoyMDk3MjA0MzUzfQ.bGSDpl9Nl8tUsBeOb1PFNsyc65AdhkWmaafkVTOoA5I")

APP_ENV = os.getenv("APP_ENV", "development").strip().lower()
# Allow mock auth only in non-production unless explicitly overridden.
ALLOW_MOCK_AUTH = _to_bool(
    os.getenv("ALLOW_MOCK_AUTH"),
    default=APP_ENV != "production",
)
