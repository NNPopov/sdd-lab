# FEATURE: revoke_moderator — outside-in test fixtures.
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

    session.commit() inside adapters creates SAVEPOINTs instead of real commits.
    Rolling back the outer transaction at teardown removes all test data.
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
async def seeded_superuser(async_client: AsyncClient) -> dict:
    """Insert a superuser User row to act as the auth identity in revoke-moderator calls."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Revoke Super",
            username="revokesuper",
            email="revokesuper@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
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
async def seeded_moderator_user(async_client: AsyncClient, seeded_superuser: dict) -> dict:
    """Insert a User row that is already a moderator, to be the revocation target.

    moderator_granted_by_user_id (init=False on the ORM model) is set via a
    second UPDATE after initial insert so the FK is satisfied and the revoke
    adapter actually clears a non-null value.
    """
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Target Moderator",
            username="revoketargetmod",
            email="revoketargetmod@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
            is_moderator=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        # moderator_granted_by_user_id is init=False; set it via UPDATE.
        await session.execute(
            sa_update(User)
            .where(User.username == "revoketargetmod")
            .values(moderator_granted_by_user_id=seeded_superuser["id"])
        )
        await session.commit()
        await session.refresh(user)

        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "name": user.name,
            "is_moderator": user.is_moderator,
        }


@pytest_asyncio.fixture()
async def seeded_regular_user(async_client: AsyncClient) -> dict:
    """Insert a non-moderator User row, used for the 409 conflict scenario."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Regular User",
            username="revokeregular",
            email="revokeregular@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return {
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "name": user.name,
            "is_moderator": user.is_moderator,
        }
