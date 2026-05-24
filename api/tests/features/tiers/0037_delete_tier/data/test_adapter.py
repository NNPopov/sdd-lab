# FEATURE: delete_tier — adapter unit tests (real test Postgres).
#
# Covers: F9, F10.
from datetime import datetime

import pytest
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from app.features.tiers._shared.entities import TierItem
from app.features.tiers.delete_tier.data.adapter import DeleteTierAdapter

pytestmark = pytest.mark.asyncio


def _make_adapter() -> DeleteTierAdapter:
    from app.bootstrap.container import container as _di_container

    return DeleteTierAdapter(session_factory=_di_container.session_factory())


async def _seed_tier(name: str) -> int:
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": name},
        )
        tier_id: int = result.scalar_one()
        await session.commit()
    return tier_id


async def _cleanup(*names: str) -> None:
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        for name in names:
            await session.execute(text("DELETE FROM tier WHERE name = :n"), {"n": name})
        await session.commit()


# ── F9a: get happy path ───────────────────────────────────────────────────────


async def test_get_returns_tier_item_when_found() -> None:
    """F9a — existing tier → TierItem with correct id, name, created_at."""
    tier_id = await _seed_tier("adapter_del_get_silver")
    try:
        adapter = _make_adapter()
        result = await adapter.get(tier_id)
        assert isinstance(result, TierItem)
        assert result.id == tier_id
        assert result.name == "adapter_del_get_silver"
        assert isinstance(result.created_at, datetime)
    finally:
        await _cleanup("adapter_del_get_silver")


# ── F9b: get not-found ────────────────────────────────────────────────────────


async def test_get_returns_none_when_tier_absent() -> None:
    """F9b — no row with that id → None."""
    adapter = _make_adapter()
    result = await adapter.get(999999999)
    assert result is None


# ── F10a: delete happy path ────────────────────────────────────────────────────


async def test_delete_removes_tier_row() -> None:
    """F10a — delete(tier_id) → row no longer exists in the database."""
    tier_id = await _seed_tier("adapter_del_silver")
    try:
        adapter = _make_adapter()
        await adapter.delete(tier_id)

        from app.bootstrap.container import container as _di_container

        async with _di_container.session_factory()() as session:
            result = await session.execute(
                text("SELECT id FROM tier WHERE id = :id"),
                {"id": tier_id},
            )
            assert result.first() is None, "tier row still present after delete"
    finally:
        await _cleanup("adapter_del_silver")


# ── F10b: delete no-op ─────────────────────────────────────────────────────────


async def test_delete_noop_when_id_not_in_table() -> None:
    """F10b — delete with an id not in the table completes without error."""
    adapter = _make_adapter()
    await adapter.delete(999999999)


# ── N2: unknown exception propagates unchanged ────────────────────────────────


async def test_delete_propagates_db_error_unchanged() -> None:
    """N2 — adapter does not catch unknown infrastructure exceptions."""
    from unittest.mock import AsyncMock, MagicMock

    adapter = _make_adapter()
    mock_session = MagicMock()
    mock_session.__aenter__ = AsyncMock(return_value=mock_session)
    mock_session.__aexit__ = AsyncMock(return_value=False)
    mock_session.execute = AsyncMock(side_effect=OperationalError("db down", None, None))

    adapter._session_factory = MagicMock(return_value=mock_session)

    with pytest.raises(OperationalError):
        await adapter.delete(1)
