import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from database import get_db
from models import Base
from settings import TEST_DATABASE_URL, APP_ENV
from main import app


@pytest_asyncio.fixture(scope="session", autouse=True)
def safety_check():
    """
    Autouse session fixture to prevent executing test teardowns or writes
    against production or live Supabase databases.
    """
    if APP_ENV == "production":
        raise RuntimeError(
            "CRITICAL SAFETY SHUTDOWN: Cannot run integration tests in a production environment (APP_ENV=production)."
        )

    # Prevent dropping database tables on live Supabase projects
    for host_pattern in ["supabase.com", "supabase.co", "pooler.supabase.com"]:
        if host_pattern in TEST_DATABASE_URL:
            raise RuntimeError(
                f"CRITICAL SAFETY SHUTDOWN: The TEST_DATABASE_URL points to a live database server ({host_pattern}). "
                f"Running tests would drop all metadata. Please set a local TEST_DATABASE_URL or point to a local postgres container."
            )


@pytest_asyncio.fixture(scope="function")
async def test_engine():
    """
    Creates a database engine for testing, drops existing tables,
    and sets up the schema fresh for the test run.
    """
    engine = create_async_engine(TEST_DATABASE_URL, echo=False, future=True)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def db_session(test_engine):
    """
    Spawns a clean AsyncSession bound to the test engine, rolling back
    the transaction upon test teardown.
    """
    AsyncSessionLocal = sessionmaker(
        bind=test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with AsyncSessionLocal() as session:
        yield session
        await session.rollback()


@pytest.fixture(autouse=True)
def override_db_dependency(db_session):
    """
    Automatically overrides FastAPI's get_db dependency to point to the
    active test database session, reverting it after each test is run.
    """
    app.dependency_overrides[get_db] = lambda: db_session
    yield
    app.dependency_overrides.pop(get_db, None)
