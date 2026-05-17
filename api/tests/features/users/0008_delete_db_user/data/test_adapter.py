# FEATURE: delete_db_user — adapter unit tests.
#
# Covers: F4 (get_by_username), F5 (db_delete), F6 (IntegrityError → DuplicateValueDomainError).
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


# ── get_by_username ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_username_returns_target_for_active_row() -> None:
    """F4a — active row found → DbDeleteUserTarget returned."""
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.username = "alice"
    row.is_deleted = False

    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    target = await _make_adapter(session).get_by_username("alice")

    assert isinstance(target, DbDeleteUserTarget)
    assert target.username == "alice"


@pytest.mark.asyncio
async def test_get_by_username_returns_target_for_soft_deleted_row() -> None:
    """F4b — soft-deleted row found → DbDeleteUserTarget returned (no is_deleted filter)."""
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.username = "alice"
    row.is_deleted = True

    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    target = await _make_adapter(session).get_by_username("alice")

    assert isinstance(target, DbDeleteUserTarget)
    assert target.username == "alice"


@pytest.mark.asyncio
async def test_get_by_username_returns_none_when_row_missing() -> None:
    """F4c — no matching row → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_username("ghost") is None


# ── db_delete ─────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_db_delete_raises_duplicate_value_on_integrity_error() -> None:
    """F6 — IntegrityError from commit → DuplicateValueDomainError."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=IntegrityError("FK violation", params=None, orig=Exception()))

    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await _make_adapter(session).db_delete("alice")
    assert "dependent" in exc_info.value.message.lower()


@pytest.mark.asyncio
async def test_db_delete_propagates_other_db_errors() -> None:
    """N2 — non-IntegrityError from db_delete propagates unchanged."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=RuntimeError("unexpected db failure"))

    with pytest.raises(RuntimeError, match="unexpected db failure"):
        await _make_adapter(session).db_delete("alice")
