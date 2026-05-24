# FEATURE: update_user_route_to_user_id — adapter unit tests.
#
# Covers: F10, F11, F12.
from unittest.mock import AsyncMock, MagicMock

import pytest
from sqlalchemy.exc import IntegrityError

from app.domain.errors import DuplicateValueDomainError
from app.features.users.update_user.data.adapter import UpdateUserAdapter
from app.features.users.update_user.domain.commands import UpdateUserCommand
from app.features.users.update_user.domain.entities import ExistingUser

_UPDATE_CMD = UpdateUserCommand(
    target_user_id=1,
    requester_user_id=1,
    name="Alice Updated",
    email=None,
    username=None,
    profile_image_url=None,
)


def _make_adapter(session_mock: MagicMock) -> UpdateUserAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return UpdateUserAdapter(session_factory=factory)


# ── F10: get_by_id ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_id_returns_existing_user_when_found() -> None:
    """F10 — active row found by integer PK → ExistingUser with id, username, email."""
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.id = 1
    row.username = "alice"
    row.email = "alice@example.com"

    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    adapter = _make_adapter(session)
    user = await adapter.get_by_id(1)

    assert isinstance(user, ExistingUser)
    assert user.id == 1
    assert user.username == "alice"
    assert user.email == "alice@example.com"


@pytest.mark.asyncio
async def test_get_by_id_returns_none_when_not_found() -> None:
    """F10 — no matching row → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    adapter = _make_adapter(session)
    assert await adapter.get_by_id(999) is None


# ── F12: update — IntegrityError translation ──────────────────────────────────


@pytest.mark.asyncio
async def test_update_integrity_error_maps_to_duplicate_value() -> None:
    """F12 — IntegrityError on commit → DuplicateValueDomainError."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=IntegrityError("dup", {}, None))

    adapter = _make_adapter(session)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await adapter.update(_UPDATE_CMD)
    assert exc_info.value.message == "Email or username already taken"


@pytest.mark.asyncio
async def test_update_propagates_non_integrity_error() -> None:
    """N2 — non-IntegrityError propagates unchanged."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=RuntimeError("unexpected"))

    adapter = _make_adapter(session)
    with pytest.raises(RuntimeError, match="unexpected"):
        await adapter.update(_UPDATE_CMD)
