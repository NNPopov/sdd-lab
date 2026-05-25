# FEATURE: delete_db_user — adapter unit tests.
#
# Covers: F8/F9 (get_by_id), F10 (db_delete), F11 (IntegrityError → DuplicateValueDomainError).
from unittest.mock import AsyncMock, MagicMock

import pytest
from sqlalchemy.exc import IntegrityError

from app.domain.errors import DuplicateValueDomainError
from app.features.users.delete_db_user.data.adapter import DeleteDbUserAdapter
from app.features.users.delete_db_user.domain.entities import DbDeleteUserTarget


def _make_adapter(session_mock: MagicMock) -> DeleteDbUserAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return DeleteDbUserAdapter(session_factory=factory)


# ── get_by_id ─────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_id_returns_target_when_row_found() -> None:
    """F8/F9 — row found → DbDeleteUserTarget(id=...) returned."""
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.id = 42

    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    target = await _make_adapter(session).get_by_id(42)

    assert isinstance(target, DbDeleteUserTarget)
    assert target.id == 42


@pytest.mark.asyncio
async def test_get_by_id_returns_none_when_row_missing() -> None:
    """F9 — no matching row → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_id(999) is None


# ── db_delete ─────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_db_delete_raises_duplicate_value_on_integrity_error() -> None:
    """F11 — IntegrityError from commit → DuplicateValueDomainError."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=IntegrityError("FK violation", params=None, orig=Exception()))

    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await _make_adapter(session).db_delete(42)
    assert "dependent" in exc_info.value.message.lower()


@pytest.mark.asyncio
async def test_db_delete_propagates_other_db_errors() -> None:
    """N2 — non-IntegrityError from db_delete propagates unchanged."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=RuntimeError("unexpected db failure"))

    with pytest.raises(RuntimeError, match="unexpected db failure"):
        await _make_adapter(session).db_delete(42)
