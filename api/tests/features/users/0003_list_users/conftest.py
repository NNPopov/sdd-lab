# FEATURE: list_users — outside-in test fixtures.
from datetime import UTC, datetime

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine — each test gets its own engine."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test transaction rollback via savepoints."""
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


@pytest_asyncio.fixture()
async def make_user(async_client: AsyncClient):
    """Factory: insert a User ORM row through the overridden session factory.

    Returns an async callable.  Each call creates one user with a unique
    username/email derived from an internal counter.  Pass
    ``is_deleted=True`` for a soft-deleted row.
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    counter = 0

    async def _factory(*, is_deleted: bool = False) -> User:
        nonlocal counter
        counter += 1
        n = counter
        async with _di_container.session_factory()() as session:
            user = User(
                name=f"Test User {n}",
                username=f"oit3testuser{n}",
                email=f"oit3testuser{n}@example.com",
                hashed_password="hashed_pw",
                is_deleted=is_deleted,
                deleted_at=datetime.now(UTC) if is_deleted else None,
            )
            session.add(user)
            await session.commit()
            await session.refresh(user)
            return user

    return _factory
