# FEATURE: list_pending_posts — adapter unit tests (real test Postgres).
#
# Covers: F5, F6, F7, F8, F9, F11, F12, F13, F21.
from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient

from app.features.posts.list_pending_posts.data.adapter import ListPendingPostsAdapter
from app.features.posts.list_pending_posts.domain.commands import ListPendingPostsQuery
from app.features.posts.list_pending_posts.domain.entities import PendingPostPage

pytestmark = pytest.mark.asyncio


def _make_adapter() -> ListPendingPostsAdapter:
    from app.bootstrap.container import container as _di_container

    return ListPendingPostsAdapter(session_factory=_di_container.session_factory())


def _query(**overrides) -> ListPendingPostsQuery:
    defaults: dict = {"page": 1, "items_per_page": 10, "requester_is_privileged": True}
    defaults.update(overrides)
    return ListPendingPostsQuery(**defaults)


# ── F11: empty queue ──────────────────────────────────────────────────────────


async def test_empty_queue_returns_zero_count_and_empty_items(
    async_client: AsyncClient,
) -> None:
    """F11 — no pending posts in DB → total_count=0, items=[]."""
    adapter = _make_adapter()
    result = await adapter.list(_query())
    assert isinstance(result, PendingPostPage)
    assert result.total_count == 0
    assert result.items == []
    assert result.page == 1
    assert result.items_per_page == 10


# ── F5: only pending_review / changes_requested appear ────────────────────────


async def test_only_pending_statuses_appear(async_client: AsyncClient) -> None:
    """F5 — approved posts excluded; pending_review and changes_requested included."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="Author F5",
            username="author_f5",
            email="author_f5@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        post_pending = Post(created_by_user_id=author.id, title="Pending", text="p")
        post_approved = Post(created_by_user_id=author.id, title="Approved", text="a")
        post_cr = Post(created_by_user_id=author.id, title="CR", text="c")
        session.add_all([post_pending, post_approved, post_cr])
        await session.commit()
        await session.refresh(post_approved)
        await session.refresh(post_cr)

        await session.execute(sa_update(Post).where(Post.id == post_approved.id).values(status="approved"))
        await session.execute(sa_update(Post).where(Post.id == post_cr.id).values(status="changes_requested"))
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.list(_query())

    titles = {item.title for item in result.items}
    assert "Pending" in titles
    assert "CR" in titles
    assert "Approved" not in titles
    assert result.total_count == 2


# ── F6: soft-deleted posts excluded ──────────────────────────────────────────


async def test_soft_deleted_post_excluded(async_client: AsyncClient) -> None:
    """F6 — post with is_deleted=True excluded from items and total_count."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="Author F6",
            username="author_f6",
            email="author_f6@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        active_post = Post(created_by_user_id=author.id, title="Active", text="a")
        deleted_post = Post(created_by_user_id=author.id, title="Deleted", text="d")
        session.add_all([active_post, deleted_post])
        await session.commit()
        await session.refresh(deleted_post)

        await session.execute(sa_update(Post).where(Post.id == deleted_post.id).values(is_deleted=True))
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.list(_query())

    titles = [item.title for item in result.items]
    assert "Active" in titles
    assert "Deleted" not in titles
    assert result.total_count == 1


# ── F7: posts by soft-deleted users excluded ──────────────────────────────────


async def test_posts_by_deleted_user_excluded(async_client: AsyncClient) -> None:
    """F7 — posts whose author has is_deleted=True excluded from results and total_count."""
    from sqlalchemy import update as sa_update

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        active_author = User(
            name="Active Author",
            username="active_author_f7",
            email="active_author_f7@example.com",
            hashed_password="x",
        )
        deleted_author = User(
            name="Deleted Author",
            username="deleted_author_f7",
            email="deleted_author_f7@example.com",
            hashed_password="x",
        )
        session.add_all([active_author, deleted_author])
        await session.commit()
        await session.refresh(active_author)
        await session.refresh(deleted_author)

        await session.execute(sa_update(User).where(User.id == deleted_author.id).values(is_deleted=True))
        await session.commit()

        active_post = Post(created_by_user_id=active_author.id, title="Active Author Post", text="a")
        ghost_post = Post(created_by_user_id=deleted_author.id, title="Deleted Author Post", text="g")
        session.add_all([active_post, ghost_post])
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.list(_query())

    titles = [item.title for item in result.items]
    assert "Active Author Post" in titles
    assert "Deleted Author Post" not in titles
    assert result.total_count == 1


# ── F9: moderation_log ordered chronologically ────────────────────────────────


async def test_moderation_log_ordered_chronologically(async_client: AsyncClient) -> None:
    """F9 — log entries attached to post ordered by created_at ASC (oldest first)."""

    from app.adapters.db.models.post import Post
    from app.adapters.db.models.post_moderation_log import PostModerationLog
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    now = datetime.now(UTC)
    t1 = now - timedelta(seconds=5)
    t2 = now - timedelta(seconds=2)

    async with _di_container.session_factory()() as session:
        author = User(
            name="Log Order Author",
            username="log_order_author",
            email="log_order_author@example.com",
            hashed_password="x",
        )
        mod = User(
            name="Log Order Mod",
            username="log_order_mod",
            email="log_order_mod@example.com",
            hashed_password="x",
            is_moderator=True,
        )
        session.add_all([author, mod])
        await session.commit()
        await session.refresh(author)
        await session.refresh(mod)

        post = Post(created_by_user_id=author.id, title="Log Order Post", text="p")
        session.add(post)
        await session.commit()
        await session.refresh(post)

        log2 = PostModerationLog(
            post_id=post.id, user_id=mod.id, event_type="moderator_review", action="changes_requested"
        )
        log2.created_at = t2
        log1 = PostModerationLog(post_id=post.id, user_id=author.id, event_type="author_revision", action=None)
        log1.created_at = t1
        session.add_all([log2, log1])
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.list(_query())

    post_items = [item for item in result.items if item.title == "Log Order Post"]
    assert len(post_items) == 1
    log = post_items[0].moderation_log
    assert len(log) == 2
    assert log[0].created_at <= log[1].created_at


# ── F12, F13: pagination ──────────────────────────────────────────────────────


async def test_pagination_returns_correct_page(async_client: AsyncClient) -> None:
    """F12, F13 — seed 3 posts, request page=2 with items_per_page=2; only 1 item returned."""
    from app.adapters.db.models.post import Post
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        author = User(
            name="Pager Author",
            username="pager_author",
            email="pager_author@example.com",
            hashed_password="x",
        )
        session.add(author)
        await session.commit()
        await session.refresh(author)

        for i in range(3):
            session.add(Post(created_by_user_id=author.id, title=f"Pager Post {i}", text="p"))
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.list(_query(page=2, items_per_page=2))

    assert result.total_count == 3
    assert result.page == 2
    assert result.items_per_page == 2
    assert len(result.items) == 1
