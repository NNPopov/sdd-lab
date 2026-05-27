# FEATURE: migrate_get_post_route_username_to_user_id — adapter unit tests (real test Postgres).
#
# Covers: F10, F11, F12. Validates the integer-keyed filter
# (Post.created_by_user_id == query.user_id), the retained User JOIN that sources
# the display username, and the soft-delete guards.
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


async def _seed_user(*, username: str, is_deleted: bool = False):
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name=f"GP54 {username}",
            username=username,
            email=f"{username}@example.com",
            hashed_password="x",
            is_deleted=is_deleted,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user


async def _seed_post(*, user_id: int, status: str = "approved", is_deleted: bool = False):
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=user_id,
            title="Adapter Post",
            text="body text",
            status=status,
            is_deleted=is_deleted,
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return post


# ── isinstance / class declaration ────────────────────────────────────────────


async def test_adapter_is_instance_of_port() -> None:
    """Adapter must explicitly inherit GetPostPort (greppable binding)."""
    from unittest.mock import MagicMock

    adapter = GetPostAdapter(session_factory=MagicMock())
    assert isinstance(adapter, GetPostPort)


# ── F10/F11: found by integer id, username from JOIN ──────────────────────────


async def test_returns_post_item_with_username_from_join(async_client: AsyncClient) -> None:
    """F10/F11 — matching user_id and post_id → PostItem with username from the User JOIN."""
    user = await _seed_user(username="gp54adpalice")
    post = await _seed_post(user_id=user.id, status="approved")

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=post.id))

    assert isinstance(result, PostItem)
    assert result.id == post.id
    assert result.created_by_user_id == user.id
    assert result.username == user.username  # resolved via the JOIN, not echoed
    assert result.title == post.title
    assert result.post_uuid == post.uuid


# ── F11: wrong author → None ──────────────────────────────────────────────────


async def test_returns_none_for_wrong_author(async_client: AsyncClient) -> None:
    """F11 — post exists but belongs to a different user_id → None."""
    owner = await _seed_user(username="gp54adpowner")
    other = await _seed_user(username="gp54adpother")
    post = await _seed_post(user_id=owner.id, status="approved")

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=other.id, post_id=post.id))
    assert result is None


# ── F11: missing post → None ──────────────────────────────────────────────────


async def test_returns_none_when_post_missing(async_client: AsyncClient) -> None:
    """F11 — user exists but post id not found → None."""
    user = await _seed_user(username="gp54adpbob")

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=99999))
    assert result is None


# ── F12: soft-deleted post → None ─────────────────────────────────────────────


async def test_returns_none_for_soft_deleted_post(async_client: AsyncClient) -> None:
    """F12 — post is_deleted=True → None."""
    user = await _seed_user(username="gp54adpcarol")
    post = await _seed_post(user_id=user.id, status="approved", is_deleted=True)

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=post.id))
    assert result is None


# ── F12: soft-deleted author → None ───────────────────────────────────────────


async def test_returns_none_for_soft_deleted_author(async_client: AsyncClient) -> None:
    """F12 — author is_deleted=True → None (User.is_deleted guard on the JOIN)."""
    user = await _seed_user(username="gp54adpdan", is_deleted=True)
    post = await _seed_post(user_id=user.id, status="approved")

    adapter = _make_adapter()
    result = await adapter.get(_query(user_id=user.id, post_id=post.id))
    assert result is None
