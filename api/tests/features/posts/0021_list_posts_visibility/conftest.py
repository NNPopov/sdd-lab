# FEATURE: list_posts_visibility — outside-in test fixtures.
from unittest.mock import AsyncMock

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.adapters.cache.redis_cache as _cache_module
from app.adapters.db.base import Base
from app.adapters.db.session import DATABASE_URL


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

    Mocks the Redis client so the @cache decorator on the list_posts endpoint
    does not raise MissingClientError. Cache-specific behaviour is verified in
    the endpoint integration test.
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

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="http://test",
        ) as client:
            yield client
    finally:
        _di_container.session_factory.reset_override()
        _cache_module.client = None
        await transaction.rollback()
        await connection.close()


@pytest_asyncio.fixture()
async def alice_user(async_client: AsyncClient) -> dict:
    """Insert alice (post author) into the test DB and return her user dict."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice Visibility",
            username="oit21alice",
            email="oit21alice@example.com",
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
async def bob_user(async_client: AsyncClient) -> dict:
    """Insert bob (different user, not alice's posts author) and return his user dict."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Bob Viewer",
            username="oit21bob",
            email="oit21bob@example.com",
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
async def alice_posts(alice_user: dict, async_client: AsyncClient) -> list:
    """Seed three posts for alice — two pending_review, one approved.

    Returns a list of dicts: [{"id": ..., "status": ...}, ...] in order,
    where the first entry is the approved post.
    """
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    # Create three posts (all default to pending_review at the DB level).
    post_ids: list[int] = []
    async with _di_container.session_factory()() as session:
        post_objs: list[Post] = []
        for i in range(1, 4):
            post = Post(
                created_by_user_id=alice_user["id"],
                title=f"Alice Post {i}",
                text=f"Content of Alice post {i}.",
            )
            session.add(post)
            post_objs.append(post)
        await session.commit()
        # expire_on_commit=False keeps IDs accessible without a refresh.
        post_ids = [p.id for p in post_objs]

    # Promote the first post to approved via a direct SQL update.
    approved_id = post_ids[0]
    async with _di_container.session_factory()() as session:
        await session.execute(
            text('UPDATE "post" SET status = :status WHERE id = :id'),
            {"status": "approved", "id": approved_id},
        )
        await session.commit()

    return [
        {"id": approved_id, "status": "approved"},
        *[{"id": pid, "status": "pending_review"} for pid in post_ids[1:]],
    ]
