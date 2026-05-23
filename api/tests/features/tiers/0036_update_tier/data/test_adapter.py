# FEATURE: update_tier — adapter unit tests (real test Postgres).
#
# Covers: F12, F13, F14, F15, F16.
from datetime import datetime

import pytest
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from app.features.tiers._shared.entities import TierItem
from app.features.tiers.update_tier.data.adapter import UpdateTierAdapter

pytestmark = pytest.mark.asyncio


def _make_adapter() -> UpdateTierAdapter:
    from app.bootstrap.container import container as _di_container

    return UpdateTierAdapter(session_factory=_di_container.session_factory())


async def _seed_tier(name: str) -> None:
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW())"),
            {"name": name},
        )
        await session.commit()


async def _cleanup(*names: str) -> None:
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        for name in names:
            await session.execute(text("DELETE FROM tier WHERE name = :n"), {"n": name})
        await session.commit()


# ── F12: get happy path ───────────────────────────────────────────────────────


async def test_get_returns_tier_item_when_found() -> None:
    """F12 — existing tier → TierItem with correct id, name, created_at."""
    await _seed_tier("adapter_silver_get")
    try:
        adapter = _make_adapter()
        result = await adapter.get("adapter_silver_get")
        assert isinstance(result, TierItem)
        assert result.name == "adapter_silver_get"
        assert isinstance(result.id, int) and result.id > 0
        assert isinstance(result.created_at, datetime)
    finally:
        await _cleanup("adapter_silver_get")


# ── F13: get not-found ────────────────────────────────────────────────────────


async def test_get_returns_none_when_tier_absent() -> None:
    """F13 — no row with that name → None."""
    adapter = _make_adapter()
    result = await adapter.get("nonexistent_tier_xyz_99")
    assert result is None


# ── F14: update happy path ────────────────────────────────────────────────────


async def test_update_renames_tier_and_sets_updated_at() -> None:
    """F14 — update('silver', 'gold') → row has name='gold' and non-null updated_at."""
    await _seed_tier("adapter_silver_upd")
    try:
        adapter = _make_adapter()
        await adapter.update("adapter_silver_upd", "adapter_gold_upd")

        from app.bootstrap.container import container as _di_container

        async with _di_container.session_factory()() as session:
            result = await session.execute(
                text("SELECT name, updated_at FROM tier WHERE name = :n"),
                {"n": "adapter_gold_upd"},
            )
            row = result.first()
        assert row is not None
        assert row.name == "adapter_gold_upd"
        assert row.updated_at is not None
    finally:
        await _cleanup("adapter_silver_upd", "adapter_gold_upd")


# ── F15: update duplicate → DuplicateValueDomainError ────────────────────────


async def test_update_duplicate_name_raises_duplicate_value_domain_error() -> None:
    """F15 — rename to an already-taken name → DuplicateValueDomainError."""
    from app.domain.errors import DuplicateValueDomainError

    await _seed_tier("adapter_silver_dup")
    await _seed_tier("adapter_gold_dup")
    try:
        adapter = _make_adapter()
        with pytest.raises(DuplicateValueDomainError) as exc_info:
            await adapter.update("adapter_silver_dup", "adapter_gold_dup")
        assert exc_info.value.message == "Tier name already exists"
    finally:
        await _cleanup("adapter_silver_dup", "adapter_gold_dup")


# ── F16: unknown exception propagates ─────────────────────────────────────────


async def test_update_non_integrity_error_propagates_unchanged() -> None:
    """F16 — OperationalError propagates unchanged; adapter does not swallow it."""
    from unittest.mock import AsyncMock, MagicMock

    adapter = _make_adapter()
    mock_session = MagicMock()
    mock_session.__aenter__ = AsyncMock(return_value=mock_session)
    mock_session.__aexit__ = AsyncMock(return_value=False)
    mock_session.execute = AsyncMock(side_effect=OperationalError("db down", None, None))

    adapter._session_factory = MagicMock(return_value=mock_session)

    with pytest.raises(OperationalError):
        await adapter.update("silver", "gold")
