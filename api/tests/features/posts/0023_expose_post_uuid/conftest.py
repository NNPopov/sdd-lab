# FEATURE: expose_post_uuid — outside-in test fixtures.
from unittest.mock import AsyncMock

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.adapters.cache.redis_cache as _cache_module
from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL, async_get_db


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine — creates schema on the dev DB, disposed after test."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test savepoint-mode transaction rollback.

    Overrides both the DI container's session_factory AND the legacy async_get_db
    dependency so that hexagonal adapters (list_posts, list_all_posts, create_post)
    and the legacy read_post endpoint all see the same test transaction.
    Mocks the Redis client to prevent MissingClientError on all cached endpoints.
    """
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app

    mock_redis = AsyncMock()
    mock_redis.get.return_value = None  # always simulate cache miss
    _cache_module.client = mock_redis

    connection = await oit_engine.connect()
    transaction = await connection.begin()
    test_factory = async_sessionmaker(
        bind=connection,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    _di_container.session_factory.override(test_factory)

    async def _test_async_get_db():
        async with test_factory() as session:
            yield session

    _fastapi_app.dependency_overrides[async_get_db] = _test_async_get_db

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="http://test",
        ) as client:
            yield client
    finally:
        del _fastapi_app.dependency_overrides[async_get_db]
        _di_container.session_factory.reset_override()
        _cache_module.client = None
        await transaction.rollback()
        await connection.close()


@pytest_asyncio.fixture()
async def seeded_alice(async_client: AsyncClient) -> dict:
    """Insert one active User row for alice via the overridden session factory.

    Returns a dict suitable for injecting via get_current_user / get_optional_user
    dependency overrides.
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice UUID Test",
            username="oit23alice",
            email="oit23alice@example.com",
            hashed_password="fake_hashed_password",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "name": user.name,
            "is_superuser": user.is_superuser,
            "is_moderator": getattr(user, "is_moderator", False),
        }
