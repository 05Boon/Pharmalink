import asyncio
from database import engine
from models import Base

async def init_db():
    print("Creating tables inside your PostGIS Docker container...")
    async with engine.begin() as conn:
        # This looks at models.py and creates any tables that don't exist yet
        await conn.run_sync(Base.metadata.create_all)
    print("Tables created successfully!")

if __name__ == "__main__":
    asyncio.run(init_db())