# FEATURE: migrate_list_posts_route_username_to_user_id — adapter unit tests.
#
# Covers: F11 (filter on Post.created_by_user_id, not User.username),
#         F12 (is_author = requester_user_id == user_id; None → public view,
#              which applies the status='approved' filter),
#         F13 (Post→User JOIN + User.is_deleted guard retained in BOTH the
#              count and rows statements; each PostItem.username is sourced
#              from the JOIN), plus PostPage shape, empty result, and the
#              read-only adapter's no-try/except infra-error propagation (N2).
#
# The session is mocked. The rows query is select(Post, User.username), so the
# rows result yields (Post, str) tuples and is read via .all() — not
# .scalars().all(). The count statement (select(func.count())) selects no Post
# columns, so SQL-token assertions on the WHERE clause use it: a status or
# username reference there can only come from a filter, never from a SELECT.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.posts.list_posts.data.adapter import ListPostsAdapter
from app.features.posts.list_posts.domain.commands import ListPostsQuery
from app.features.posts.list_posts.domain.ports.list_posts_port import ListPostsPort


def _make_post_row(*, id: int, username: str = "alicepost") -> tuple[MagicMock, str]:
    """Build a (Post-mock, username) tuple as returned by the JOIN query."""
    post = MagicMock()
    post.id = id
    post.title = f"Post {id}"
    post.text = "Some text"
    post.media_url = None
    post.created_at = datetime(2024, 1, 1, tzinfo=UTC)
    post.created_by_user_id = 7
    post.status = "approved"
    post.uuid = uuid.UUID(f"00000000-0000-0000-0000-{id:012d}")
    return (post, username)


def _make_adapter(*, count: int, rows: list[tuple[MagicMock, str]]) -> tuple[ListPostsAdapter, MagicMock]:
    """Build an adapter whose session mock returns count then rows; return (adapter, session)."""
    count_result = MagicMock()
    count_result.scalar_one.return_value = count

    rows_result = MagicMock()
    rows_result.all.return_value = rows  # two-column select → .all(), not .scalars().all()

    session = MagicMock()
    session.execute = AsyncMock(side_effect=[count_result, rows_result])

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return ListPostsAdapter(session_factory=session_factory), session


def _count_sql(session) -> str:
    return str(session.execute.await_args_list[0].args[0]).lower()


def _rows_sql(session) -> str:
    return str(session.execute.await_args_list[1].args[0]).lower()


# ── explicit port inheritance (N8) ────────────────────────────────────────────


def test_adapter_is_instance_of_port() -> None:
    adapter = ListPostsAdapter(session_factory=MagicMock())
    assert isinstance(adapter, ListPostsPort)


# ── PostPage assembly + username from JOIN (F13) ──────────────────────────────


@pytest.mark.asyncio
async def test_returns_postpage_with_username_from_join() -> None:
    rows = [_make_post_row(id=1), _make_post_row(id=2)]
    adapter, _ = _make_adapter(count=2, rows=rows)

    result = await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10))

    assert result.total_count == 2
    assert result.page == 1
    assert result.items_per_page == 10
    assert len(result.items) == 2
    assert [item.id for item in result.items] == [1, 2]
    assert all(item.username == "alicepost" for item in result.items)
    assert all(item.created_by_user_id == 7 for item in result.items)


@pytest.mark.asyncio
async def test_total_count_reflects_full_db_count_not_page_size() -> None:
    rows = [_make_post_row(id=i) for i in range(1, 6)]
    adapter, _ = _make_adapter(count=42, rows=rows)

    result = await adapter.list(ListPostsQuery(user_id=7, page=2, items_per_page=5))

    assert result.total_count == 42
    assert result.page == 2
    assert result.items_per_page == 5
    assert len(result.items) == 5


@pytest.mark.asyncio
async def test_empty_result_returns_empty_page() -> None:
    """F6/F7: a user_id with no visible (or no existing) posts → empty page, no error."""
    adapter, _ = _make_adapter(count=0, rows=[])

    result = await adapter.list(ListPostsQuery(user_id=999999, page=1, items_per_page=10))

    assert result.items == []
    assert result.total_count == 0


# ── filter on created_by_user_id, not username (F11) ──────────────────────────


@pytest.mark.asyncio
async def test_filters_on_created_by_user_id_not_username() -> None:
    adapter, session = _make_adapter(count=0, rows=[])

    await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10))

    count_sql = _count_sql(session)
    rows_sql = _rows_sql(session)
    # Both statements filter the post set on the author's integer id.
    assert "post.created_by_user_id =" in count_sql
    assert "post.created_by_user_id =" in rows_sql
    # The count statement selects no User columns, so a username reference there
    # could only be a leftover username filter — there must be none.
    assert "username" not in count_sql


# ── JOIN + is_deleted guard retained in both statements (F13) ─────────────────


@pytest.mark.asyncio
async def test_join_and_is_deleted_guard_in_both_statements() -> None:
    adapter, session = _make_adapter(count=0, rows=[])

    await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10))

    for sql in (_count_sql(session), _rows_sql(session)):
        assert "join" in sql
        assert "is_deleted" in sql  # both user.is_deleted and post.is_deleted render this token


# ── is_author branch controls the approved filter (F12) ───────────────────────


@pytest.mark.asyncio
async def test_public_view_applies_approved_filter() -> None:
    """requester_user_id is None → not author → status='approved' filter applied."""
    adapter, session = _make_adapter(count=0, rows=[])

    await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10, requester_user_id=None))

    # The count statement selects no Post columns, so post.status appearing there
    # can only come from the status filter.
    assert "post.status =" in _count_sql(session)


@pytest.mark.asyncio
async def test_non_owner_requester_is_treated_as_public() -> None:
    """requester_user_id != user_id → not author → status='approved' filter applied."""
    adapter, session = _make_adapter(count=0, rows=[])

    await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10, requester_user_id=99))

    assert "post.status =" in _count_sql(session)


@pytest.mark.asyncio
async def test_author_view_omits_approved_filter() -> None:
    """requester_user_id == user_id → author → no status filter (sees all non-deleted)."""
    adapter, session = _make_adapter(count=0, rows=[])

    await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10, requester_user_id=7))

    assert "post.status =" not in _count_sql(session)


# ── infrastructure exception propagates unchanged (N2) ────────────────────────


@pytest.mark.asyncio
async def test_infrastructure_exception_propagates_unchanged() -> None:
    """N2: the read-only adapter has no try/except; any infra error escapes to the caller."""
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    adapter = ListPostsAdapter(session_factory=session_factory)

    with pytest.raises(RuntimeError, match="db boom"):
        await adapter.list(ListPostsQuery(user_id=7, page=1, items_per_page=10))
