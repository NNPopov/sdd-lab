# FEATURE: delete_tier — adapter unit tests (real test Postgres).
#
# Covers: F7, F8.
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


# ── F7a: get happy path ───────────────────────────────────────────────────────


async def test_get_returns_tier_item_when_found() -> None:
    """F7a — existing tier → TierItem with correct id, name, created_at."""
    await _seed_tier("adapter_del_get_silver")
    try:
        adapter = _make_adapter()
        result = await adapter.get("adapter_del_get_silver")
        assert isinstance(result, TierItem)
        assert result.name == "adapter_del_get_silver"
        assert isinstance(result.id, int) and result.id > 0
        assert isinstance(result.created_at, datetime)
    finally:
        await _cleanup("adapter_del_get_silver")


# ── F7b: get not-found ────────────────────────────────────────────────────────


async def test_get_returns_none_when_tier_absent() -> None:
    """F7b — no row with that name → None."""
    adapter = _make_adapter()
    result = await adapter.get("nonexistent_tier_del_xyz_99")
    assert result is None


# ── F8a: delete happy path ────────────────────────────────────────────────────


async def test_delete_removes_tier_row() -> None:
    """F8a — delete('silver') → row no longer exists in the database."""
    await _seed_tier("adapter_del_silver")
    try:
        adapter = _make_adapter()
        await adapter.delete("adapter_del_silver")

        from app.bootstrap.container import container as _di_container

        async with _di_container.session_factory()() as session:
            result = await session.execute(
                text("SELECT id FROM tier WHERE name = :n"),
                {"n": "adapter_del_silver"},
            )
            assert result.first() is None, "tier row still present after delete"
    finally:
        await _cleanup("adapter_del_silver")


# ── F8b: delete no-op ─────────────────────────────────────────────────────────


async def test_delete_noop_when_name_not_in_table() -> None:
    """F8b — delete with a name not in the table completes without error."""
    adapter = _make_adapter()
    await adapter.delete("nonexistent_tier_del_noop_xyz")


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
        await adapter.delete("silver")
