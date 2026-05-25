# FEATURE: rate_limits_route_to_user_id — outside-in test fixtures.
#
# Fat-handler migration slice: read_user_rate_limits injects the session via
# Depends(async_get_db), bypassing the DI container. The async_client fixture
# therefore overrides BOTH container.session_factory AND async_get_db so the
# free function and any container-wired code share the same savepoint
# transaction. See agent_docs/testing.md § Fat-handler migration slices.
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
    """HTTP client wired to the app with per-test savepoint-mode transaction rollback.

    session.commit() inside the function/repositories creates SAVEPOINTs instead
    of real commits. Rolling back the outer transaction at teardown removes all
    test data. async_get_db is overridden so the fat handler reads through the
    same test transaction.
    """
    from app.adapters.db.session import async_get_db
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

    async def _test_get_db():
        async with test_factory() as session:
            yield session

    _fastapi_app.dependency_overrides[async_get_db] = _test_get_db

    try:
        async with AsyncClient(
            transport=ASGITransport(app=_fastapi_app),
            base_url="http://test",
        ) as client:
            yield client
    finally:
        _fastapi_app.dependency_overrides.pop(async_get_db, None)
        _di_container.session_factory.reset_override()
        await transaction.rollback()
        await connection.close()


@pytest_asyncio.fixture()
async def seeded_superuser(async_client: AsyncClient) -> dict:
    """Insert a superuser User row to act as the auth identity for the request."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="RL Super",
            username="rl049super",
            email="rl049super@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
            is_superuser=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return {
            "id": user.id,
            "name": user.name,
            "username": user.username,
            "email": user.email,
            "profile_image_url": user.profile_image_url,
            "is_superuser": user.is_superuser,
            "is_moderator": user.is_moderator,
            "tier_id": user.tier_id,
        }


@pytest_asyncio.fixture()
async def seeded_user_with_tier(async_client: AsyncClient) -> dict:
    """Insert a tier, a rate-limit row for that tier, and a user linked to the tier.

    User.tier_id is init=False on the ORM model, so it is set via a second UPDATE
    after the initial insert.
    """
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.rate_limit import RateLimit
    from app.adapters.db.models.tier import Tier
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        tier = Tier(name="rl049_pro")
        session.add(tier)
        await session.commit()
        await session.refresh(tier)

        rate_limit = RateLimit(
            tier_id=tier.id,
            name="rl049_login",
            path="login",
            limit=10,
            period=60,
        )
        session.add(rate_limit)
        await session.commit()

        user = User(
            name="RL Target",
            username="rl049target",
            email="rl049target@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        # tier_id is init=False; set it via UPDATE.
        await session.execute(sa_update(User).where(User.id == user.id).values(tier_id=tier.id))
        await session.commit()
        await session.refresh(user)

        return {
            "id": user.id,
            "name": user.name,
            "username": user.username,
            "email": user.email,
            "profile_image_url": user.profile_image_url,
            "tier_id": tier.id,
            "rate_limit_name": rate_limit.name,
        }
