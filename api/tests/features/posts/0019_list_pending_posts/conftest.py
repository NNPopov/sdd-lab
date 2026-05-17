# FEATURE: list_pending_posts — outside-in test fixtures.
from datetime import UTC, datetime, timedelta

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
async def seeded_lpp_author(async_client: AsyncClient) -> dict:
    """Insert a regular (non-moderator) User row to act as the post author."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="LPP Author",
            username="lppauthor",
            email="lppauthor@example.com",
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
async def seeded_lpp_moderator(async_client: AsyncClient) -> dict:
    """Insert a User row with is_moderator=True to act as the reviewing moderator."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="LPP Moderator",
            username="lppmod",
            email="lppmod@example.com",
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
async def seeded_lpp_plain_user(async_client: AsyncClient) -> dict:
    """Insert a plain User row (no moderator, no superuser) for the 403 scenario."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="LPP Plain",
            username="lppplain",
            email="lppplain@example.com",
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
async def seeded_lpp_post_with_log_entries(
    seeded_lpp_author: dict,
    seeded_lpp_moderator: dict,
    async_client: AsyncClient,
) -> dict:
    """Insert a Post in pending_review with two ordered PostModerationLog entries.

    Log layout:
      entry 0 — event_type='moderator_review', action='changes_requested' (t1)
      entry 1 — event_type='author_revision', action=None              (t2 > t1)
    Post ends in status='pending_review' after the author's revision.
    """
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.post_moderation_log import PostModerationLog
    from app.bootstrap.container import container as _di_container

    now = datetime.now(UTC)
    t1 = now - timedelta(seconds=2)
    t2 = now

    async with _di_container.session_factory()() as session:
        # Create a pending post owned by the author.
        post = Post(
            created_by_user_id=seeded_lpp_author["id"],
            title="Review This Post",
            text="Content waiting for moderation.",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)

        # Insert the first log entry (moderator requested changes) with timestamp t1.
        log1 = PostModerationLog(
            post_id=post.id,
            user_id=seeded_lpp_moderator["id"],
            event_type="moderator_review",
            action="changes_requested",
            message="Please clarify section 2.",
        )
        log1.created_at = t1
        session.add(log1)

        # Advance post status to changes_requested.
        await session.execute(sa_update(Post).where(Post.id == post.id).values(status="changes_requested"))
        await session.commit()

        # Insert the second log entry (author revised) with timestamp t2.
        log2 = PostModerationLog(
            post_id=post.id,
            user_id=seeded_lpp_author["id"],
            event_type="author_revision",
            action=None,
            message="Clarified section 2.",
        )
        log2.created_at = t2
        session.add(log2)

        # Return post to pending_review.
        await session.execute(sa_update(Post).where(Post.id == post.id).values(status="pending_review"))
        await session.commit()
        await session.refresh(post)

        return {
            "id": post.id,
            "uuid": post.uuid,
            "status": post.status,
            "t1_iso": t1.isoformat(),
            "t2_iso": t2.isoformat(),
        }
