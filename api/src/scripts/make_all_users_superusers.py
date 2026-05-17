# FEATURE: scripts — one-time execution: make all existing users superusers.
import asyncio
import logging
import sys
from pathlib import Path

# Ensure the src directory is on sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import text  # noqa: E402

from app.adapters.db.session import async_engine  # noqa: E402

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def make_all_users_superusers() -> None:
    try:
        stmt = text("UPDATE public.user SET is_superuser = TRUE")

        async with async_engine.connect() as conn:
            result = await conn.execute(stmt)
            await conn.commit()

        logger.info(f"Updated {result.rowcount} user(s) to is_superuser=True.")

    except Exception as e:
        logger.error(f"Error making users superusers: {e}")


async def main():
    await make_all_users_superusers()


if __name__ == "__main__":
    asyncio.run(main())
