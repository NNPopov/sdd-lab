# FEATURE: revise_post — outside-in test fixtures.
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
async def seeded_revise_author(async_client: AsyncClient) -> dict:
    """Insert a regular User row to act as the post author."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="Revise Author",
            username="reviseauthor",
            email="reviseauthor@example.com",
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
async def seeded_changes_requested_post(
    seeded_revise_author: dict,
    async_client: AsyncClient,
) -> dict:
    """Insert a Post owned by seeded_revise_author with status='changes_requested'."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_revise_author["id"],
            title="Original Title",
            text="Original body text.",
            status="changes_requested",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return {
            "id": post.id,
            "uuid": post.uuid,
            "status": post.status,
            "title": post.title,
            "text": post.text,
        }


@pytest_asyncio.fixture()
async def seeded_pending_review_post(
    seeded_revise_author: dict,
    async_client: AsyncClient,
) -> dict:
    """Insert a Post owned by seeded_revise_author with the default status='pending_review'."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_revise_author["id"],
            title="Fresh Post",
            text="Not yet moderated.",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return {
            "id": post.id,
            "uuid": post.uuid,
            "status": post.status,
        }
