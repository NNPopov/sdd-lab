# FEATURE: get_post — adapter unit tests (real test Postgres).
#
# Covers: F15, F16, F17.
import pytest
from httpx import AsyncClient

from app.features.posts._shared.entities import PostItem
from app.features.posts.get_post.data.adapter import GetPostAdapter
from app.features.posts.get_post.domain.commands import GetPostQuery
from app.features.posts.get_post.domain.ports.get_post_port import GetPostPort

pytestmark = pytest.mark.asyncio


def _make_adapter() -> GetPostAdapter:
    from app.bootstrap.container import container as _di_container

    return GetPostAdapter(session_factory=_di_container.session_factory())


def _query(user_id: int, post_id: int) -> GetPostQuery:
    return GetPostQuery(user_id=user_id, post_id=post_id)


# ── isinstance / class declaration ────────────────────────────────────────────


async def test_adapter_is_instance_of_port() -> None:
    """Adapter must explicitly inherit GetPostPort (greppable binding)."""
    from unittest.mock import MagicMock

    adapter = GetPostAdapter(session_factory=MagicMock())
    assert isinstance(adapter, GetPostPort)


# ── F15: happy path — all fields populated ────────────────────────────────────


async def test_returns_post_item_with_all_fields(async_client: AsyncClient) -> None:
    """F15 — user and post exist, not deleted → PostItem with username and post_uuid."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP26 Adapter Alice",
            username="gp26adpalice",
            email="gp26adpalice@example.com",
            hashed_password="x",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        post = Post(created_by_user_id=user.id, title="Adapter Post", text="body text")
        session.add(post)
        await session.commit()
        await session.refresh(post)

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=post.id))

    assert isinstance(result, PostItem)
    assert result.id == post.id
    assert result.username == user.username
    assert result.title == post.title
    assert result.text == post.text
    assert result.media_url is None
    assert result.created_by_user_id == user.id
    assert result.post_uuid == post.uuid


# ── F16: user does not exist ─────────────────────────────────────────────────


async def test_returns_none_when_user_missing(async_client: AsyncClient) -> None:
    """F16 — user_id not in DB → None."""
    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=999999, post_id=1))
    assert result is None


# ── F16: post does not exist for that user ────────────────────────────────────


async def test_returns_none_when_post_missing(async_client: AsyncClient) -> None:
    """F16 — username exists but post id not found → None."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP26 Adapter Bob",
            username="gp26adpbob",
            email="gp26adpbob@example.com",
            hashed_password="x",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=99999))
    assert result is None


# ── F16: soft-deleted post ────────────────────────────────────────────────────


async def test_returns_none_for_soft_deleted_post(async_client: AsyncClient) -> None:
    """F16 — post exists but is_deleted=True → None."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP26 Adapter Carol",
            username="gp26adpcarol",
            email="gp26adpcarol@example.com",
            hashed_password="x",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        post = Post(created_by_user_id=user.id, title="Deleted", text="body")
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_id = post.id

        await session.execute(sa_update(Post).where(Post.id == post_id).values(is_deleted=True))
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=post_id))
    assert result is None


# ── F17: pending_review post returned without status filter ──────────────────


async def test_returns_pending_review_post(async_client: AsyncClient) -> None:
    """F17 — adapter returns pending_review post; no status filter applied."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="GP26 Adapter Dave",
            username="gp26adpdave",
            email="gp26adpdave@example.com",
            hashed_password="x",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)

        post = Post(
            created_by_user_id=user.id,
            title="Pending Post",
            text="still under review",
            status="pending_review",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=post.id))

    assert result is not None
    assert result.status == "pending_review"
