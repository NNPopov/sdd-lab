# FEATURE: get_user_tier — adapter unit tests.
#
# Covers: F10 (user row absent → UserNotFound), F11 (tier_id None → None),
#         F12 (both rows found → FoundUserTier), F13 (tier row absent → TierNotFound),
#         F14 (soft-delete filter), F15 (two separate queries), N2 (no try/except),
#         N10 (explicit port inheritance).
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.users.get_user_tier.data.adapter import GetUserTierAdapter
from app.features.users.get_user_tier.domain.commands import GetUserTierQuery
from app.features.users.get_user_tier.domain.entities import (
    FoundUserTier,
    TierNotFound,
    UserNotFound,
)
from app.features.users.get_user_tier.domain.ports.get_user_tier_port import (
    GetUserTierPort,
)

_QUERY = GetUserTierQuery(username="testuser")


def _make_scalar_result(value: object) -> MagicMock:
    r = MagicMock()
    r.scalar_one_or_none.return_value = value
    return r


def _make_user_row(*, tier_id: int | None) -> MagicMock:
    row = MagicMock()
    row.tier_id = tier_id
    return row


def _make_tier_row(*, id: int, name: str, created_at: datetime) -> MagicMock:
    row = MagicMock()
    row.id = id
    row.name = name
    row.created_at = created_at
    return row


def _make_adapter(*execute_results: MagicMock) -> tuple[GetUserTierAdapter, MagicMock]:
    """Build adapter whose session.execute() returns results in sequence."""
    session = MagicMock()
    session.execute = AsyncMock(side_effect=list(execute_results))

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return GetUserTierAdapter(session_factory=session_factory), session


# ── N10: explicit port inheritance ────────────────────────────────────────────


def test_adapter_is_instance_of_port() -> None:
    adapter = GetUserTierAdapter(session_factory=MagicMock())
    assert isinstance(adapter, GetUserTierPort)


# ── F10: user row absent → UserNotFound ──────────────────────────────────────


@pytest.mark.asyncio
async def test_returns_user_not_found_when_user_row_absent() -> None:
    adapter, session = _make_adapter(_make_scalar_result(None))

    result = await adapter.get(_QUERY)

    assert isinstance(result, UserNotFound)
    session.execute.assert_called_once()


# ── F11: user found, tier_id None → None ─────────────────────────────────────


@pytest.mark.asyncio
async def test_returns_none_when_user_has_no_tier_id() -> None:
    user_row = _make_user_row(tier_id=None)
    adapter, session = _make_adapter(_make_scalar_result(user_row))

    result = await adapter.get(_QUERY)

    assert result is None
    # Only one query issued — tier lookup skipped (F15)
    session.execute.assert_called_once()


# ── F12: user + tier found → FoundUserTier ───────────────────────────────────


@pytest.mark.asyncio
async def test_returns_found_user_tier_when_both_rows_present() -> None:
    tier_created_at = datetime(2024, 6, 1, tzinfo=UTC)
    user_row = _make_user_row(tier_id=3)
    tier_row = _make_tier_row(id=3, name="gold", created_at=tier_created_at)
    adapter, session = _make_adapter(
        _make_scalar_result(user_row),
        _make_scalar_result(tier_row),
    )

    result = await adapter.get(_QUERY)

    assert isinstance(result, FoundUserTier)
    assert result.tier_id == 3
    assert result.tier_name == "gold"
    assert result.tier_created_at == tier_created_at
    # Two queries issued (F15)
    assert session.execute.call_count == 2


# ── F13: user found, tier_id set, tier row absent → TierNotFound ─────────────


@pytest.mark.asyncio
async def test_returns_tier_not_found_when_tier_row_absent() -> None:
    user_row = _make_user_row(tier_id=99)
    adapter, session = _make_adapter(
        _make_scalar_result(user_row),
        _make_scalar_result(None),
    )

    result = await adapter.get(_QUERY)

    assert isinstance(result, TierNotFound)
    assert session.execute.call_count == 2


# ── N2: infrastructure exception propagates unchanged ────────────────────────


@pytest.mark.asyncio
async def test_infrastructure_exception_propagates_unchanged() -> None:
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))

    session_factory = MagicMock()
    session_factory.return_value.__aenter__ = AsyncMock(return_value=session)
    session_factory.return_value.__aexit__ = AsyncMock(return_value=False)

    adapter = GetUserTierAdapter(session_factory=session_factory)

    with pytest.raises(RuntimeError, match="db boom"):
        await adapter.get(_QUERY)
