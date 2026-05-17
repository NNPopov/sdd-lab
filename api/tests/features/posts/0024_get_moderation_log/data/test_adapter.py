# FEATURE: get_moderation_log — adapter unit tests (real test Postgres).
#
# Covers: F3, F4, F11, F13, F14.
import uuid
from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient

from app.features.posts.get_moderation_log.data.adapter import GetModerationLogAdapter
from app.features.posts.get_moderation_log.domain.entities import PostForModerationLog

pytestmark = pytest.mark.asyncio


def _make_adapter() -> GetModerationLogAdapter:
    from app.bootstrap.container import container as _di_container

    return GetModerationLogAdapter(session_factory=_di_container.session_factory())


# ── F14, F3: get_post_by_uuid — UUID not found ───────────────────────────────


async def test_get_post_by_uuid_returns_none_when_missing(async_client: AsyncClient) -> None:
    """F14, F3 — non-existent UUID → None returned."""
    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(uuid.uuid4())
    assert result is None


# ── F4: get_post_by_uuid — soft-deleted post ─────────────────────────────────


async def test_get_post_by_uuid_returns_none_for_soft_deleted(async_client: AsyncClient) -> None:
    """F4 — post with is_deleted=True → None returned."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="Deleted Post Author",
            username="del_post_author_gml",
            email="del_post_author_gml@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        post = Post(created_by_user_id=author.id, title="To Delete", text="body")
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_uuid = post.uuid

        await session.execute(sa_update(Post).where(Post.id == post.id).values(is_deleted=True))
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(post_uuid)
    assert result is None


# ── F14: get_post_by_uuid — found ────────────────────────────────────────────


async def test_get_post_by_uuid_returns_correct_fields(async_client: AsyncClient) -> None:
    """F14 — existing non-deleted post → PostForModerationLog with correct id and created_by_user_id."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="Found Post Author",
            username="found_gml_author",
            email="found_gml_author@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        post = Post(created_by_user_id=author.id, title="Found Post", text="body")
        session.add(post)
        await session.commit()
        await session.refresh(post)

    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(post.uuid)

    assert isinstance(result, PostForModerationLog)
    assert result.id == post.id
    assert result.created_by_user_id == author.id


# ── F10: get_log — no entries ─────────────────────────────────────────────────


async def test_get_log_returns_empty_list_when_no_entries(async_client: AsyncClient) -> None:
    """F10 — post with no log entries → empty list returned."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="No Log Author",
            username="no_log_author_gml",
            email="no_log_author_gml@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        post = Post(created_by_user_id=author.id, title="No Log Post", text="body")
        session.add(post)
        await session.commit()
        await session.refresh(post)

    adapter = _make_adapter()
    result = await adapter.get_log(post.id)
    assert result == []


# ── F11, F13: get_log — entries present, ordered, actor_username resolved ─────


async def test_get_log_returns_entries_ordered_asc_with_actor_username(async_client: AsyncClient) -> None:
    """F11, F13 — two log entries → ordered oldest first; actor_username resolved via JOIN."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.post_moderation_log import PostModerationLog
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    now = datetime.now(UTC)
    t1 = now - timedelta(seconds=5)
    t2 = now

    async with _di_container.session_factory()() as session:
        author = User(
            name="Log Author",
            username="log_author_gml",
            email="log_author_gml@example.com",
            hashed_password="x",
        )
        mod = User(
            name="Log Mod",
            username="log_mod_gml",
            email="log_mod_gml@example.com",
            hashed_password="x",
            is_moderator=True,
        )
        session.add_all([author, mod])
        await session.commit()
        await session.refresh(author)
        await session.refresh(mod)

        post = Post(created_by_user_id=author.id, title="Log Test Post", text="body")
        session.add(post)
        await session.commit()
        await session.refresh(post)

        log1 = PostModerationLog(
            post_id=post.id,
            user_id=mod.id,
            event_type="moderator_review",
            action="changes_requested",
            message="Fix it.",
        )
        log1.created_at = t1
        log2 = PostModerationLog(
            post_id=post.id,
            user_id=author.id,
            event_type="author_revision",
            action=None,
            message="Fixed.",
        )
        log2.created_at = t2
        session.add_all([log1, log2])
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get_log(post.id)

    assert len(result) == 2
    assert result[0].created_at <= result[1].created_at
    assert result[0].actor_username == "log_mod_gml"
    assert result[1].actor_username == "log_author_gml"
    assert result[0].event_type == "moderator_review"
    assert result[1].event_type == "author_revision"


# ── get_log — entries from other posts excluded ───────────────────────────────


async def test_get_log_excludes_entries_from_other_posts(async_client: AsyncClient) -> None:
    """get_log only returns entries for the given post_id; other posts' entries excluded."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.post_moderation_log import PostModerationLog
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="Exclude Author",
            username="exclude_author_gml",
            email="exclude_author_gml@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        post_a = Post(created_by_user_id=author.id, title="Post A", text="body")
        post_b = Post(created_by_user_id=author.id, title="Post B", text="body")
        session.add_all([post_a, post_b])
        await session.commit()
        await session.refresh(post_a)
        await session.refresh(post_b)

        log_a = PostModerationLog(post_id=post_a.id, user_id=author.id, event_type="moderator_review", action=None)
        log_b = PostModerationLog(post_id=post_b.id, user_id=author.id, event_type="author_revision", action=None)
        session.add_all([log_a, log_b])
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get_log(post_a.id)

    assert len(result) == 1
    assert result[0].event_type == "moderator_review"
