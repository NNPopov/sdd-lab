# FEATURE: refactor_token_blacklist — outside-in test fixtures.
from collections.abc import AsyncGenerator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL
from app.adapters.db.session import async_get_db as _real_async_get_db


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine connected to the same DB as the app."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture()
async def _oit_connection(oit_engine):
    """Single connection shared by async_client and oit_db_session for one test."""
    connection = await oit_engine.connect()
    transaction = await connection.begin()
    yield connection
    await transaction.rollback()
    await connection.close()


@pytest_asyncio.fixture()
async def oit_db_session(_oit_connection) -> AsyncSession:
    """AsyncSession on the shared connection — used for direct DB-state assertions."""
    factory = async_sessionmaker(bind=_oit_connection, expire_on_commit=False)
    session = factory()
    try:
        yield session
    finally:
        await session.close()


@pytest_asyncio.fixture()
async def async_client(_oit_connection) -> AsyncGenerator[AsyncClient, None]:
    """HTTP client wired to the app with per-test transaction rollback.

    Overrides both the DI container session_factory and the async_get_db FastAPI
    dependency so that all DB writes (create_user, blacklist) go through the test
    connection and are rolled back at teardown.
    """
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app

    test_factory = async_sessionmaker(
        bind=_oit_connection,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    _di_container.session_factory.override(test_factory)

    async def _override_async_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with test_factory() as session:
            yield session

    _fastapi_app.dependency_overrides[_real_async_get_db] = _override_async_get_db

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="https://test",
        ) as client:
            yield client
    finally:
        _di_container.session_factory.reset_override()
        _fastapi_app.dependency_overrides.pop(_real_async_get_db, None)
