# FEATURE: update_user_route_to_user_id — use-case unit tests.
#
# Covers: F4, F5, F6, F7, F8, F9.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from app.features.users.update_user.domain.commands import UpdateUserCommand
from app.features.users.update_user.domain.entities import ExistingUser, UpdatedUserResult
from app.features.users.update_user.domain.use_case import UpdateUserUseCase

_EXISTING = ExistingUser(id=1, username="alice", email="alice@example.com")

_CMD = UpdateUserCommand(
    target_user_id=1,
    requester_user_id=1,
    name="Alice Updated",
)


def _make_port(
    *,
    existing: ExistingUser | None = _EXISTING,
    email_exists: bool = False,
    username_exists: bool = False,
) -> MagicMock:
    port = MagicMock()
    port.get_by_id = AsyncMock(return_value=existing)
    port.email_exists = AsyncMock(return_value=email_exists)
    port.username_exists = AsyncMock(return_value=username_exists)
    port.update = AsyncMock(return_value=None)
    return port


def _make_use_case(**kwargs: object) -> UpdateUserUseCase:
    return UpdateUserUseCase(port=_make_port(**kwargs))  # type: ignore[arg-type]


# ── F4: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_raises_when_get_by_id_returns_none() -> None:
    """F4 — get_by_id returns None → NotFoundDomainError."""
    use_case = _make_use_case(existing=None)
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F5: forbidden — wrong owner ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_raised_when_requester_id_differs_from_existing_id() -> None:
    """F5 — requester_user_id != existing.id → ForbiddenDomainError; update not called."""
    cmd = UpdateUserCommand(
        target_user_id=1,
        requester_user_id=2,
        name="Hacked",
    )
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    with pytest.raises(ForbiddenDomainError):
        await use_case(cmd)
    port.update.assert_not_called()


# ── F6: duplicate email ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_email_raises_when_email_taken() -> None:
    """F6 — new email and email_exists True → DuplicateValueDomainError."""
    cmd = UpdateUserCommand(
        target_user_id=1,
        requester_user_id=1,
        email="taken@example.com",
    )
    use_case = _make_use_case(email_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "Email is already registered"


# ── F8: duplicate username ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_username_raises_when_username_taken() -> None:
    """F8 — new username and username_exists True → DuplicateValueDomainError."""
    cmd = UpdateUserCommand(
        target_user_id=1,
        requester_user_id=1,
        username="bob",
    )
    use_case = _make_use_case(username_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "Username not available"


# ── F7: email unchanged — skip email_exists ───────────────────────────────────


@pytest.mark.asyncio
async def test_email_exists_not_called_when_email_unchanged() -> None:
    """F7 — email same as existing.email → email_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    cmd = UpdateUserCommand(
        target_user_id=1,
        requester_user_id=1,
        email="alice@example.com",  # same as _EXISTING.email
    )
    await use_case(cmd)
    port.email_exists.assert_not_called()


@pytest.mark.asyncio
async def test_email_exists_not_called_when_email_is_none() -> None:
    """F7 — email=None → email_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    await use_case(UpdateUserCommand(target_user_id=1, requester_user_id=1))
    port.email_exists.assert_not_called()


# ── F9: username unchanged — skip username_exists ─────────────────────────────


@pytest.mark.asyncio
async def test_username_exists_not_called_when_username_unchanged() -> None:
    """F9 — username same as existing.username → username_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    cmd = UpdateUserCommand(
        target_user_id=1,
        requester_user_id=1,
        username="alice",  # same as _EXISTING.username
    )
    await use_case(cmd)
    port.username_exists.assert_not_called()


@pytest.mark.asyncio
async def test_username_exists_not_called_when_username_is_none() -> None:
    """F9 — username=None → username_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    await use_case(UpdateUserCommand(target_user_id=1, requester_user_id=1))
    port.username_exists.assert_not_called()


# ── happy path ────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_update_and_returns_result() -> None:
    """All checks pass → port.update called; UpdatedUserResult returned."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    result = await use_case(_CMD)
    port.update.assert_called_once_with(_CMD)
    assert isinstance(result, UpdatedUserResult)
    assert result.message == "User updated"
