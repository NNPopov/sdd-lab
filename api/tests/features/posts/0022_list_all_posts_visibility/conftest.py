# FEATURE: list_all_posts_visibility — outside-in test fixtures.
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

    Mocks the Redis client so the @cache decorator on list_all_posts does not
    raise MissingClientError. Cache-specific behaviour is verified in the
    endpoint integration test.
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
    """Regular (non-privileged) user — alice.

    Created directly via the session factory to avoid going through the full
    registration HTTP flow. `is_moderator` and `is_superuser` default to False.
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice GlobalFeed",
            username="oit22alice",
            email="oit22alice@example.com",
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
async def mod_user(async_client: AsyncClient) -> dict:
    """Moderator user — oit22mod.

    Created directly with `is_moderator=True` to avoid going through the
    assign-moderator HTTP flow. The outside-in test verifies the filter logic,
    not the moderator-assignment flow (tested by slice 0015).
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Mod GlobalFeed",
            username="oit22mod",
            email="oit22mod@example.com",
            hashed_password="fake_hashed_password",
            is_moderator=True,
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
async def posts_data(alice_user: dict, async_client: AsyncClient) -> list:
    """Seed three posts for alice — one approved, two pending_review.

    Returns a list of dicts:
      [{"id": <approved_id>, "status": "approved"}, ...]
    The first entry is always the approved post.
    """
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    post_ids: list[int] = []
    async with _di_container.session_factory()() as session:
        post_objs: list[Post] = []
        for i in range(1, 4):
            post = Post(
                created_by_user_id=alice_user["id"],
                title=f"Global Post {i}",
                text=f"Content of global post {i}.",
            )
            session.add(post)
            post_objs.append(post)
        await session.commit()
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
