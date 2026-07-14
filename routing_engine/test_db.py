import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.settings import TEST_DATABASE_URL
from app.crud import generate_admin_report

async def main():
    engine = create_async_engine(TEST_DATABASE_URL)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        try:
            report = await generate_admin_report(db, 7)
            print("SUCCESS")
            print(report.get("top_requested_drugs_by_area", []))
        except Exception as e:
            import traceback
            traceback.print_exc()

asyncio.run(main())
