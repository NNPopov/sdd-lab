# FEATURE: erase_post — outside-in test fixtures.
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

    Mocks the Redis client so the @cache decorator on the DELETE and GET endpoints
    does not raise MissingClientError. Overrides both async_get_db (used by the
    legacy erase_post and erase_db_post flat handlers) and the container's
    session_factory (used by the new erase_post adapter after the green phase)
    so both see the seeded data.
    """
    from app.bootstrap.container import container as _di_container

    mock_redis = AsyncMock()
    mock_redis.get.return_value = None  # always simulate cache miss
    mock_redis.scan.return_value = (0, [])  # empty scan — no keys to delete
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
async def ep29_alice(async_client: AsyncClient) -> dict:
    """Insert alice (post owner) via the overridden session factory; return her user dict."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EP29 Alice",
            username="ep29alice",
            email="ep29alice@example.com",
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
        }


@pytest_asyncio.fixture()
async def ep29_bob(async_client: AsyncClient) -> dict:
    """Insert bob (non-owner) via the overridden session factory; return his user dict."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EP29 Bob",
            username="ep29bob",
            email="ep29bob@example.com",
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
        }


@pytest_asyncio.fixture()
async def ep29_alice_post(ep29_alice: dict, async_client: AsyncClient) -> dict:
    """Insert an approved Post owned by alice; return its dict.

    Status 'approved' ensures the verification GET in scenario 1 would return
    200 before deletion (approved posts are publicly visible per the get_post
    slice), making the post-deletion 404 unambiguously caused by the soft-delete,
    not by visibility rules.
    """
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=ep29_alice["id"],
            title="Test post",
            text="Test text.",
            status="approved",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return {"id": post.id}
