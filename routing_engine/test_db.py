import asyncio
from sqlalchemy import text
from database import engine

async def test_connection():
    try:
        async with engine.connect() as conn:
            # Ask the database to output its version to confirm it is awake
            result = await conn.execute(text("SELECT PostGIS_Version();"))
            version = result.scalar()
            print("\nCONNECTION SUCCESSFUL!")
            print(f"PostGIS version running in Docker: {version}\n")
    except Exception as e:
        print("\nCONNECTION FAILED")
        print(f"Error details: {e}\n")

if __name__ == "__main__":
    asyncio.run(test_connection())