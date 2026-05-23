# FEATURE: list_tiers — outside-in test fixtures.
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine against the dev DB; ensures schema exists."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture(autouse=True)
async def _clean_tiers(async_client: AsyncClient) -> None:
    """Delete all tier rows before each test inside the savepoint transaction.

    Pre-existing committed rows in the dev DB would otherwise cause total_count
    assertions to fail. The outer transaction rollback in async_client teardown
    restores the DB to its pre-test state.
    """
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        await session.execute(text('UPDATE "user" SET tier_id = NULL WHERE tier_id IS NOT NULL'))
        await session.execute(text('DELETE FROM "rate_limit" WHERE tier_id IS NOT NULL'))
        await session.execute(text('DELETE FROM "tier"'))
        await session.commit()


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test transaction rollback via savepoints.

    The DI container's session_factory is overridden with a savepoint-mode factory
    so that session.commit() inside adapters creates SAVEPOINTs instead of real
    commits. Rolling back the outer transaction at teardown removes all test data.
    """
    from app.bootstrap.container import container as _di_container

    connection = await oit_engine.connect()
    transaction = await connection.begin()
    test_factory = async_sessionmaker(
        bind=connection,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    _di_container.session_factory.override(test_factory)

    from app.main import app as _fastapi_app

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="http://test",
        ) as client:
            yield client
    finally:
        _di_container.session_factory.reset_override()
        await transaction.rollback()
        await connection.close()
