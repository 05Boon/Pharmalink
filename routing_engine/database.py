import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

# 1. Look for the database URL environment variable
# If it can't find it locally, default to our Docker string
DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql+asyncpg://admin:local_secret_password@localhost:5432/pharmacy_network_db"
)

# 2. Create the Async Engine (The physical engine that manages database queries)
engine = create_async_engine(
    DATABASE_URL, 
    echo=True,  # Prints raw SQL to your terminal so you can see it working
    future=True
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