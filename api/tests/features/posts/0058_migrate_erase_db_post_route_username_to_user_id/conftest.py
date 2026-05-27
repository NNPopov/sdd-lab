# FEATURE: migrate_erase_db_post_route_username_to_user_id — outside-in test fixtures.
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
    does not raise MissingClientError; get() always reports a cache miss, so the
    verification GET in scenario 1 reads fresh data from the adapter (and a 404
    after the hard delete is the real DB state, not a stale cache hit). Overrides
    both async_get_db and the container's session_factory so every code path sees
    the seeded data inside the test transaction.
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
async def edp58_author(async_client: AsyncClient) -> dict:
    """Insert the post author (regular user) via the overridden session factory; return the dict."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EDP58 Author",
            username="edp58author",
            email="edp58author@example.com",
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
            "is_moderator": user.is_moderator,
        }


@pytest_asyncio.fixture()
async def edp58_superuser(async_client: AsyncClient) -> dict:
    """Insert a distinct superuser; return the dict (with id) for the auth override.

    Its id differs from edp58_author so the no-ownership behaviour is unambiguous
    (a superuser hard-deletes another user's post). erase_db_post resolves the
    target author from the DB and the requester only via the overridden
    get_current_user, so this row only needs is_superuser=True.
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EDP58 Super",
            username="edp58super",
            email="edp58super@example.com",
            hashed_password="fake_hashed_password",
            is_superuser=True,
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
            "is_moderator": user.is_moderator,
        }


@pytest_asyncio.fixture()
async def edp58_author_post(edp58_author: dict, async_client: AsyncClient) -> dict:
    """Insert an approved Post owned by edp58_author; return its dict.

    Status 'approved' ensures the pre-deletion GET returns 200 (approved posts
    are publicly visible per the get_post slice), making the post-deletion 404
    unambiguously caused by the hard delete, not by visibility rules.
    """
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=edp58_author["id"],
            title="Original title",
            text="Original text.",
            status="approved",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return {"id": post.id}
