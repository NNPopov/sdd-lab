# FEATURE: migrate_get_post_route_username_to_user_id — outside-in test fixtures.
from unittest.mock import AsyncMock

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.adapters.cache.redis_cache as _cache_module
from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL, async_get_db


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine — each test gets its own engine; ensures schema exists."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test savepoint-mode transaction rollback.

    Mocks the Redis client so the @cache decorator on the get_post endpoint
    does not raise MissingClientError. Cache-specific behaviour is verified
    in the endpoint integration test.
    """
    from app.bootstrap.container import container as _di_container

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

    from app.main import app as _fastapi_app

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
async def seeded_author(async_client: AsyncClient):
    """Insert one active User row through the overridden session factory and return it."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP54 Alice",
            username="gp54alice",
            email="gp54alice@example.com",
            hashed_password="hashed_pw",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user


@pytest_asyncio.fixture()
async def seeded_approved_post(seeded_author, async_client: AsyncClient):
    """Insert one approved Post for the seeded author and return it."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_author.id,
            title="Approved Post",
            text="An approved post.",
            status="approved",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return post


@pytest_asyncio.fixture()
async def seeded_pending_post(seeded_author, async_client: AsyncClient):
    """Insert one non-approved (pending) Post for the seeded author and return it."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_author.id,
            title="Pending Post",
            text="A pending post.",
            status="pending",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return post
