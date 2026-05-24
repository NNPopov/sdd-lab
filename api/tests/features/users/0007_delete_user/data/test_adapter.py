# FEATURE: delete_user — adapter unit tests.
#
# Covers: F5, F6.
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.features.users.delete_user.data.adapter import DeleteUserAdapter
from app.features.users.delete_user.domain.entities import DeleteUserTarget


def _make_adapter(session_mock: MagicMock) -> DeleteUserAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return DeleteUserAdapter(session_factory=factory)


# ── get_by_username ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_username_returns_target_when_active_row_found() -> None:
    """F5a — active row found → DeleteUserTarget returned."""
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.id = 1
    row.username = "alice"

    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    adapter = _make_adapter(session)
    target = await adapter.get_by_username("alice")

    assert isinstance(target, DeleteUserTarget)
    assert target.id == 1
    assert target.username == "alice"


@pytest.mark.asyncio
async def test_get_by_username_returns_none_when_row_missing() -> None:
    """F5b — no matching active row → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_username("ghost") is None


# ── soft_delete ───────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_soft_delete_sets_is_deleted_and_deleted_at() -> None:
    """F6 — soft_delete issues UPDATE setting is_deleted=True and non-null deleted_at."""
    captured: dict = {}

    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock()

    adapter = _make_adapter(session)

    import app.features.users.delete_user.data.adapter as adapter_module

    original_update = adapter_module.update

    def capturing_update(model, *args, **kwargs):  # type: ignore[no-untyped-def]
        stmt = original_update(model, *args, **kwargs)

        class _Spy:
            def where(self, *a, **kw):  # type: ignore[no-untyped-def]
                inner = stmt.where(*a, **kw)

                class _Spy2:
                    def values(self, **values):  # type: ignore[no-untyped-def]
                        captured["values"] = values
                        return inner.values(**values)

                return _Spy2()

        return _Spy()

    before = datetime.now(UTC)
    with patch.object(adapter_module, "update", side_effect=capturing_update):
        await adapter.soft_delete("alice")
    after = datetime.now(UTC)

    assert captured["values"]["is_deleted"] is True
    deleted_at = captured["values"]["deleted_at"]
    assert deleted_at is not None
    assert before <= deleted_at.replace(tzinfo=UTC) <= after


@pytest.mark.asyncio
async def test_soft_delete_propagates_db_error() -> None:
    """N2 — any DB error from soft_delete propagates unchanged (no catch)."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=RuntimeError("db failure"))

    adapter = _make_adapter(session)
    with pytest.raises(RuntimeError, match="db failure"):
        await adapter.soft_delete("alice")
