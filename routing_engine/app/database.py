from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.settings import DATABASE_URL, TEST_DATABASE_URL, MOCK_AUTH_BYPASS

# Automatically route to the local test container if bypass is active
ACTIVE_DB_URL = TEST_DATABASE_URL if MOCK_AUTH_BYPASS else DATABASE_URL

# 2. Create the Async Engine (The physical engine that manages database queries)
engine = create_async_engine(
    ACTIVE_DB_URL, 
    echo=True,  # Prints raw SQL to your terminal so you can see it working
    future=True,
    pool_size=5,  # Connection pool settings for better performance
    max_overflow=10 #
)

# 3. Create a Session Factory (Produces temporary connection tickets)
AsyncSessionLocal = sessionmaker(
    bind=engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

# 4. Dependency Injection function for FastAPI
async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()