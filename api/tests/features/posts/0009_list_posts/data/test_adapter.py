# FEATURE: list_posts — adapter unit tests.
#
# Covers: F4 (soft-delete filter via JOIN), F9 (offset/limit), F10 (total_count),
#         F12 (isinstance check), F13 (explicit port inheritance),
#         F14 (no exception catch — infra errors propagate).
#
# Note: the rows query uses select(Post, User.username), which returns
# (Post, str) tuples.  rows_result.all() — NOT .scalars().all() — is mocked.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.posts.list_posts.data.adapter import ListPostsAdapter
from app.features.posts.list_posts.domain.commands import ListPostsQuery
from app.features.posts.list_posts.domain.ports.list_posts_port import ListPostsPort


def _make_post_row(*, id: int, username: str = "alice") -> tuple[MagicMock, str]:
    """Build a (Post-mock, username) tuple as returned by the JOIN query."""
    post = MagicMock()
    post.id = id
    post.title = f"Post {id}"
    post.text = "Some text"
    post.media_url = None
    post.created_at = datetime(2024, 1, 1, tzinfo=UTC)
    post.created_by_user_id = 1
    post.status = "approved"
    post.uuid = uuid.UUID(f"00000000-0000-0000-0000-{id:012d}")
    return (post, username)


def _make_adapter(count: int, rows: list[tuple[MagicMock, str]]) -> ListPostsAdapter:
    """Build an adapter whose session mock returns count and rows in sequence."""
    count_result = MagicMock()
    count_result.scalar_one.return_value = count

    rows_result = MagicMock()
    rows_result.all.return_value = rows  # two-column select → .all(), not .scalars().all()

    session = MagicMock()
    session.execute = AsyncMock(side_effect=[count_result, rows_result])

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return ListPostsAdapter(session_factory=session_factory)


# ── isinstance / class declaration (F12, F13) ─────────────────────────────────


def test_adapter_is_instance_of_port() -> None:
    """F12: isinstance(adapter, ListPostsPort) must be True."""
    adapter = ListPostsAdapter(session_factory=MagicMock())
    assert isinstance(adapter, ListPostsPort)


# ── happy path: correct PostPage shape (F10) ──────────────────────────────────


@pytest.mark.asyncio
async def test_returns_correct_postpage_shape() -> None:
    rows = [
        _make_post_row(id=1, username="alice"),
        _make_post_row(id=2, username="alice"),
    ]
    adapter = _make_adapter(count=2, rows=rows)
    query = ListPostsQuery(username="alice", page=1, items_per_page=10)

    result = await adapter.list(query)

    assert result.total_count == 2
    assert result.page == 1
    assert result.items_per_page == 10
    assert len(result.items) == 2
    assert result.items[0].username == "alice"
    assert result.items[1].username == "alice"
    assert result.items[0].id == 1
    assert result.items[1].id == 2


# ── total_count reflects full DB count, not just page size (F10) ──────────────


@pytest.mark.asyncio
async def test_total_count_reflects_full_db_count_not_page_size() -> None:
    rows = [_make_post_row(id=i) for i in range(1, 6)]
    adapter = _make_adapter(count=42, rows=rows)
    query = ListPostsQuery(username="alice", page=2, items_per_page=5)

    result = await adapter.list(query)

    assert result.total_count == 42
    assert len(result.items) == 5


# ── pagination metadata echoed in response (F9) ───────────────────────────────


@pytest.mark.asyncio
async def test_pagination_page_metadata_echoed_in_response() -> None:
    rows = [_make_post_row(id=i) for i in range(6, 11)]
    adapter = _make_adapter(count=15, rows=rows)
    query = ListPostsQuery(username="alice", page=3, items_per_page=5)

    result = await adapter.list(query)

    assert result.page == 3
    assert result.items_per_page == 5
    assert len(result.items) == 5


# ── infrastructure exception propagates (F14) ─────────────────────────────────


@pytest.mark.asyncio
async def test_infrastructure_exception_propagates_unchanged() -> None:
    """F14: adapter has no try/except; any infra error escapes to the caller."""
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    adapter = ListPostsAdapter(session_factory=session_factory)

    with pytest.raises(RuntimeError, match="db boom"):
        await adapter.list(ListPostsQuery(username="alice", page=1, items_per_page=10))
