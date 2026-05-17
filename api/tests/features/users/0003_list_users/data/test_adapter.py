# FEATURE: list_users — adapter unit tests.
#
# Covers: F4 (soft-delete filter), F9 (offset), F10 (total_count), F12 (isinstance),
#         F13 (class declaration), F14 (no exception catch).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.users.list_users.data.adapter import ListUsersAdapter
from app.features.users.list_users.domain.commands import ListUsersQuery
from app.features.users.list_users.domain.ports.list_users_port import ListUsersPort


def _make_user_row(
    *,
    id: int,
    name: str = "Test User",
    username: str = "testuser",
    email: str = "test@example.com",
    profile_image_url: str = "https://profileimageurl.com",
    tier_id: int | None = None,
) -> MagicMock:
    row = MagicMock()
    row.id = id
    row.name = name
    row.username = username
    row.email = email
    row.profile_image_url = profile_image_url
    row.tier_id = tier_id
    return row


def _make_adapter(count: int, rows: list[MagicMock]) -> ListUsersAdapter:
    """Build an adapter with a session mock that returns count and rows in sequence."""
    count_result = MagicMock()
    count_result.scalar_one.return_value = count

    rows_result = MagicMock()
    rows_result.scalars.return_value.all.return_value = rows

    session = MagicMock()
    session.execute = AsyncMock(side_effect=[count_result, rows_result])

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return ListUsersAdapter(session_factory=session_factory)


# ── isinstance / class declaration (F12, F13) ─────────────────────────────────


def test_adapter_is_instance_of_port() -> None:
    """F12: isinstance(adapter, ListUsersPort) must be True."""
    adapter = ListUsersAdapter(session_factory=MagicMock())
    assert isinstance(adapter, ListUsersPort)


# ── happy path: correct UserPage shape (F10) ──────────────────────────────────


@pytest.mark.asyncio
async def test_returns_correct_userpage_shape() -> None:
    rows = [
        _make_user_row(id=1, username="u1"),
        _make_user_row(id=2, username="u2"),
    ]
    adapter = _make_adapter(count=2, rows=rows)
    query = ListUsersQuery(page=1, items_per_page=10)

    result = await adapter.list(query)

    assert result.total_count == 2
    assert result.page == 1
    assert result.items_per_page == 10
    assert len(result.items) == 2
    assert result.items[0].username == "u1"
    assert result.items[1].username == "u2"


# ── total_count is the full count, not just page size (F10) ───────────────────


@pytest.mark.asyncio
async def test_total_count_reflects_full_db_count_not_page_size() -> None:
    """total_count comes from COUNT query; items is the smaller paginated set."""
    rows = [_make_user_row(id=i, username=f"u{i}") for i in range(1, 6)]
    adapter = _make_adapter(count=47, rows=rows)
    query = ListUsersQuery(page=2, items_per_page=5)

    result = await adapter.list(query)

    assert result.total_count == 47
    assert len(result.items) == 5


# ── pagination offset (F9) ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_pagination_page_metadata_echoed_in_response() -> None:
    """page and items_per_page from query are echoed in the UserPage."""
    rows = [_make_user_row(id=i, username=f"u{i}") for i in range(6, 11)]
    adapter = _make_adapter(count=15, rows=rows)
    query = ListUsersQuery(page=2, items_per_page=5)

    result = await adapter.list(query)

    assert result.page == 2
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

    adapter = ListUsersAdapter(session_factory=session_factory)

    with pytest.raises(RuntimeError, match="db boom"):
        await adapter.list(ListUsersQuery(page=1, items_per_page=10))
