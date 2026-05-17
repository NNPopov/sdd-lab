# FEATURE: list_all_posts — outside-in test fixtures.
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.adapters.cache.redis_cache as _cache_module
from app.adapters.db.base import Base
from app.adapters.db.models.post import Post
from app.adapters.db.models.user import User
from app.adapters.db.session import DATABASE_URL


@dataclass
class SeededData:
    alice: User
    bob: User
    oldest_post: Post
    middle_post: Post
    newest_post: Post


@pytest_asyncio.fixture()
async def oit_engine():
    """Per-test async engine — creates schema, disposed on teardown."""
    engine = create_async_engine(DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest_asyncio.fixture()
async def async_client(oit_engine) -> AsyncClient:
    """HTTP client wired to the app with per-test transaction rollback via savepoints.

    Mocks the Redis client so the @cache decorator does not raise
    MissingClientError. Cache-specific behaviour is verified in the
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
async def seed_users_and_posts(async_client: AsyncClient) -> SeededData:
    """Seed two users (alice, bob) and three posts at distinct timestamps.

    Ordering: newest_post (T) > middle_post (T-60s) > oldest_post (T-120s).
    This guarantees a deterministic ORDER BY created_at DESC result.
    """
    from app.bootstrap.container import container as _di_container

    now = datetime.now(UTC)

    async with _di_container.session_factory()() as session:
        alice = User(
            name="Alice Tester",
            username="oit10alice",
            email="oit10alice@example.com",
            hashed_password="hashed_pw",
        )
        bob = User(
            name="Bob Tester",
            username="oit10bob",
            email="oit10bob@example.com",
            hashed_password="hashed_pw",
        )
        session.add(alice)
        session.add(bob)
        await session.commit()
        await session.refresh(alice)
        await session.refresh(bob)

        oldest_post = Post(
            created_by_user_id=alice.id,
            title="Oldest Post",
            text="Alice wrote this first.",
            created_at=now - timedelta(seconds=120),
            status="approved",
        )
        middle_post = Post(
            created_by_user_id=bob.id,
            title="Middle Post",
            text="Bob wrote this second.",
            created_at=now - timedelta(seconds=60),
            status="approved",
        )
        newest_post = Post(
            created_by_user_id=alice.id,
            title="Newest Post",
            text="Alice wrote this last.",
            created_at=now,
            status="approved",
        )
        session.add(oldest_post)
        session.add(middle_post)
        session.add(newest_post)
        await session.commit()
        await session.refresh(oldest_post)
        await session.refresh(middle_post)
        await session.refresh(newest_post)

    return SeededData(
        alice=alice,
        bob=bob,
        oldest_post=oldest_post,
        middle_post=middle_post,
        newest_post=newest_post,
    )
