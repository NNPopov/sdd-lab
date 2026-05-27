# FEATURE: migrate_create_post_route_username_to_user_id — outside-in test fixtures.
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

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
    """HTTP client wired to the app with per-test transaction rollback via savepoints.

    The DI container's session_factory is overridden with a savepoint-mode factory
    so that session.commit() inside adapters creates SAVEPOINTs instead of real
    commits. Rolling back the outer transaction at teardown removes all test data.

    create_post has no @cache decorator and its route does not touch the Redis
    client, so no cache mock is needed (matches slice 0011's fixtures).
    """
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
async def seeded_author(async_client: AsyncClient) -> dict:
    """Insert one active User row for the author via the overridden session factory.

    Returns a dict suitable for injecting as the get_current_user override.
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP55 Alice",
            username="gp55alice",
            email="gp55alice@example.com",
            hashed_password="hashed_pw",
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
async def seeded_other_user(async_client: AsyncClient) -> dict:
    """Insert a second, distinct active User row (the non-owner target).

    Distinct id/handle so the ownership mismatch in Scenario 2 is unambiguous.
    """
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP55 Bob",
            username="gp55bob",
            email="gp55bob@example.com",
            hashed_password="hashed_pw",
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
