# FEATURE: update_tier — outside-in test fixtures.
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


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test transaction rollback via savepoints.

    Overrides both the DI container's session_factory AND the legacy async_get_db
    dependency so that all DB operations — from the new container-wired adapter and
    from the old patch_tier handler alike — go through the same test transaction.
    Rolling back the outer transaction at teardown removes all test data without
    contaminating the dev database.
    """
    from app.adapters.db.session import async_get_db
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app

    connection = await oit_engine.connect()
    transaction = await connection.begin()
    test_factory = async_sessionmaker(
        bind=connection,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    _di_container.session_factory.override(test_factory)

    async def _test_get_db():
        async with test_factory() as session:
            yield session

    _fastapi_app.dependency_overrides[async_get_db] = _test_get_db

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="http://test",
        ) as client:
            yield client
    finally:
        _fastapi_app.dependency_overrides.pop(async_get_db, None)
        _di_container.session_factory.reset_override()
        await transaction.rollback()
        await connection.close()


@pytest_asyncio.fixture(autouse=True)
async def _clean_test_tiers(async_client: AsyncClient) -> None:
    """Delete any tier rows with names used by this test file before each test.

    Rows created by the old patch_tier handler in a previous (interrupted) red-state
    run may have been committed to the dev DB. Deleting them inside the current test
    transaction makes them invisible during the test; the outer-transaction rollback
    at teardown restores the dev DB to its pre-test state.
    """
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        await session.execute(text("DELETE FROM tier WHERE name IN ('silver', 'gold', 'platinum')"))
        await session.commit()
