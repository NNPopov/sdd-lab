# FEATURE: get_tier — adapter unit tests.
#
# Covers: F7 (happy path: row found → TierItem), F8 (not-found: absent name → None).
# Uses a mocked session factory (same approach as list_tiers adapter tests) to
# avoid event-loop teardown issues with asyncpg on Windows.
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.tiers._shared.entities import TierItem
from app.features.tiers.get_tier.data.adapter import GetTierAdapter
from app.features.tiers.get_tier.domain.commands import GetTierQuery
from app.features.tiers.get_tier.domain.ports.get_tier_port import GetTierPort

_TIER_NAME = "gold"
_CREATED_AT = datetime(2025, 1, 1, tzinfo=UTC)


def _make_adapter(*, row: object | None) -> GetTierAdapter:
    """Return a GetTierAdapter whose session.execute() yields the given row."""
    result = MagicMock()
    result.scalar_one_or_none.return_value = row

    session = MagicMock()
    session.execute = AsyncMock(return_value=result)

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return GetTierAdapter(session_factory=session_factory)


def _make_orm_row(*, id: int = 1, name: str = _TIER_NAME, created_at: datetime = _CREATED_AT) -> MagicMock:
    row = MagicMock()
    row.id = id
    row.name = name
    row.created_at = created_at
    return row


# ── Port inheritance ──────────────────────────────────────────────────────────


def test_adapter_is_instance_of_port() -> None:
    """N10 — GetTierAdapter explicitly inherits GetTierPort."""
    adapter = GetTierAdapter(session_factory=MagicMock())
    assert isinstance(adapter, GetTierPort)


# ── F7: happy path — row found ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_returns_tier_item_when_row_exists() -> None:
    """F7 — scalar_one_or_none returns a row; adapter maps it to TierItem."""
    orm_row = _make_orm_row(id=42, name=_TIER_NAME, created_at=_CREATED_AT)
    adapter = _make_adapter(row=orm_row)

    result = await adapter.get(GetTierQuery(name=_TIER_NAME))

    assert isinstance(result, TierItem)
    assert result.id == 42
    assert result.name == _TIER_NAME
    assert result.created_at == _CREATED_AT


# ── F8: not-found path — row absent ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_returns_none_when_row_absent() -> None:
    """F8 — scalar_one_or_none returns None; adapter returns None."""
    adapter = _make_adapter(row=None)

    result = await adapter.get(GetTierQuery(name="nonexistent"))

    assert result is None


# ── N2: infrastructure exception propagates unchanged ────────────────────────


@pytest.mark.asyncio
async def test_infrastructure_exception_propagates_unchanged() -> None:
    """N2 — adapter has no try/except; RuntimeError propagates to caller."""
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    adapter = GetTierAdapter(session_factory=session_factory)

    with pytest.raises(RuntimeError, match="db boom"):
        await adapter.get(GetTierQuery(name="any"))
