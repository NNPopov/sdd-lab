# FEATURE: list_posts — outside-in test fixtures.
from datetime import UTC, datetime
from unittest.mock import AsyncMock

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

import app.adapters.cache.redis_cache as _cache_module
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
async def seeded_user(async_client: AsyncClient):
    """Insert one active User row through the overridden session factory and return it."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice Tester",
            username="alicepost",
            email="alicepost@example.com",
            hashed_password="hashed_pw",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user


@pytest_asyncio.fixture()
async def make_user(async_client: AsyncClient):
    """Factory: insert a User row and return an async callable.

    Each call creates one user with a unique username/email.
    Pass ``is_deleted=True`` for a soft-deleted row.
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
                username=f"oit9testuser{n}",
                email=f"oit9testuser{n}@example.com",
                hashed_password="hashed_pw",
                is_deleted=is_deleted,
                deleted_at=datetime.now(UTC) if is_deleted else None,
            )
            session.add(user)
            await session.commit()
            await session.refresh(user)
            return user

    return _factory


@pytest_asyncio.fixture()
async def make_post(async_client: AsyncClient):
    """Factory: insert a Post row for a given user and return an async callable.

    Pass ``is_deleted=True`` for a soft-deleted row.
    """
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    counter = 0

    async def _factory(*, user_id: int, is_deleted: bool = False, status: str = "approved") -> Post:
        nonlocal counter
        counter += 1
        n = counter
        async with _di_container.session_factory()() as session:
            post = Post(
                created_by_user_id=user_id,
                title=f"Post {n}",
                text=f"Content of post {n}.",
                is_deleted=is_deleted,
                deleted_at=datetime.now(UTC) if is_deleted else None,
                status=status,
            )
            session.add(post)
            await session.commit()
            await session.refresh(post)
            return post

    return _factory


@pytest_asyncio.fixture()
async def seeded_posts(seeded_user, async_client: AsyncClient):
    """Insert two active Post rows for the seeded user and return them as a list."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post1 = Post(
            created_by_user_id=seeded_user.id,
            title="First Post",
            text="Content of the first post.",
            status="approved",
        )
        post2 = Post(
            created_by_user_id=seeded_user.id,
            title="Second Post",
            text="Content of the second post.",
            status="approved",
        )
        session.add(post1)
        session.add(post2)
        await session.commit()
        await session.refresh(post1)
        await session.refresh(post2)
        return [post1, post2]
