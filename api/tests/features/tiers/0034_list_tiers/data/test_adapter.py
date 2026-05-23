# FEATURE: list_tiers — adapter unit tests.
#
# Covers: F9 (COUNT + SELECT), F10 (id-ascending order), F11 (pagination),
#         N2 (no try/except — infra errors propagate), N11 (explicit port inheritance).
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.tiers.list_tiers.data.adapter import ListTiersAdapter
from app.features.tiers.list_tiers.domain.commands import ListTiersQuery
from app.features.tiers.list_tiers.domain.ports.list_tiers_port import ListTiersPort


def _make_tier_row(*, id: int, name: str) -> MagicMock:
    row = MagicMock()
    row.id = id
    row.name = name
    row.created_at = datetime(2024, 1, id, tzinfo=UTC)
    return row


def _make_adapter(count: int, rows: list[MagicMock]) -> ListTiersAdapter:
    count_result = MagicMock()
    count_result.scalar_one.return_value = count

    rows_result = MagicMock()
    rows_result.scalars.return_value.all.return_value = rows

    session = MagicMock()
    session.execute = AsyncMock(side_effect=[count_result, rows_result])

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return ListTiersAdapter(session_factory=session_factory)


# ── N11: explicit port inheritance ────────────────────────────────────────────


def test_adapter_is_instance_of_port() -> None:
    adapter = ListTiersAdapter(session_factory=MagicMock())
    assert isinstance(adapter, ListTiersPort)


# ── happy path: correct TierPage shape (F9, F10) ─────────────────────────────


@pytest.mark.asyncio
async def test_returns_correct_tierpage_shape() -> None:
    rows = [_make_tier_row(id=1, name="free"), _make_tier_row(id=2, name="pro")]
    adapter = _make_adapter(count=2, rows=rows)
    query = ListTiersQuery(page=1, items_per_page=10)

    result = await adapter.list(query)

    assert result.total_count == 2
    assert result.page == 1
    assert result.items_per_page == 10
    assert len(result.items) == 2
    assert result.items[0].id == 1
    assert result.items[0].name == "free"
    assert result.items[1].id == 2
    assert result.items[1].name == "pro"


# ── empty table returns zero total and empty items (F2) ──────────────────────


@pytest.mark.asyncio
async def test_empty_table_returns_zero_total_and_empty_items() -> None:
    adapter = _make_adapter(count=0, rows=[])
    query = ListTiersQuery(page=1, items_per_page=10)

    result = await adapter.list(query)

    assert result.total_count == 0
    assert result.items == []


# ── total_count reflects full DB count, not just page size (F11) ─────────────


@pytest.mark.asyncio
async def test_total_count_reflects_full_count_not_page_size() -> None:
    rows = [_make_tier_row(id=i, name=f"t{i}") for i in range(1, 3)]
    adapter = _make_adapter(count=3, rows=rows)
    query = ListTiersQuery(page=1, items_per_page=2)

    result = await adapter.list(query)

    assert result.total_count == 3
    assert len(result.items) == 2


# ── pagination metadata echoed in response (F9) ───────────────────────────────


@pytest.mark.asyncio
async def test_pagination_page_metadata_echoed_in_response() -> None:
    rows = [_make_tier_row(id=3, name="t3")]
    adapter = _make_adapter(count=3, rows=rows)
    query = ListTiersQuery(page=2, items_per_page=2)

    result = await adapter.list(query)

    assert result.page == 2
    assert result.items_per_page == 2
    assert len(result.items) == 1


# ── N2: infrastructure exception propagates unchanged ────────────────────────


@pytest.mark.asyncio
async def test_infrastructure_exception_propagates_unchanged() -> None:
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    adapter = ListTiersAdapter(session_factory=session_factory)

    with pytest.raises(RuntimeError, match="db boom"):
        await adapter.list(ListTiersQuery(page=1, items_per_page=10))
