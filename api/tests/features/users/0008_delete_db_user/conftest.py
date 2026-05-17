# FEATURE: delete_db_user — outside-in test fixtures.
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
async def seeded_alice(async_client: AsyncClient) -> dict:
    """Insert one active User row for 'alice' via the overridden session factory."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice Tester",
            username="alice",
            email="alice@example.com",
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
            "is_superuser": user.is_superuser,
        }


@pytest_asyncio.fixture()
async def seeded_alice_with_post(async_client: AsyncClient) -> dict:
    """Insert an active User row for 'alice' plus one Post that references alice.id.

    The FK reference (post.created_by_user_id → user.id) is what triggers
    IntegrityError when alice is hard-deleted, exercising the 409 path.
    """
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Alice Tester",
            username="alice",
            email="alice@example.com",
            hashed_password="fake_hashed_password",
            profile_image_url="https://www.profileimageurl.com",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        post = Post(
            created_by_user_id=user.id,
            title="Test Post",
            text="Post content for FK violation test.",
        )
        session.add(post)
        await session.commit()
        return {"id": user.id, "username": user.username}
