# FEATURE: update_user — use-case unit tests.
#
# Covers: F7–F13.
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


# ── F7: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_raises_when_user_missing() -> None:
    """F7 — port returns None → NotFoundDomainError."""
    use_case = _make_use_case(existing=None)
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F8: forbidden — wrong owner ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_raised_when_requester_is_not_owner() -> None:
    """F8 — requester_user_id != existing.id → ForbiddenDomainError."""
    """F8 — requester_user_id != existing.id → ForbiddenDomainError."""
    cmd = UpdateUserCommand(
        target_username="alice",
        requester_user_id=2,
        target_user_id=1,
        name="Hacked",
    )
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    with pytest.raises(ForbiddenDomainError):
        await use_case(cmd)
    port.update.assert_not_called()


# ── F9: duplicate email ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_email_raises_when_email_taken() -> None:
    """F9 — new email and email_exists True → DuplicateValueDomainError."""
    cmd = UpdateUserCommand(
        target_username="alice",
        requester_user_id=1,
        target_user_id=1,
        email="taken@example.com",
    )
    use_case = _make_use_case(email_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "Email is already registered"


# ── F10: duplicate username ───────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_username_raises_when_username_taken() -> None:
    """F10 — new username and username_exists True → DuplicateValueDomainError."""
    cmd = UpdateUserCommand(
        target_username="alice",
        requester_user_id=1,
        target_user_id=1,
        username="bob",
    )
    use_case = _make_use_case(username_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "Username not available"


# ── F11: skip email_exists when email is None or unchanged ────────────────────


@pytest.mark.asyncio
async def test_email_exists_not_called_when_email_is_none() -> None:
    """F11a — email=None → email_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    await use_case(UpdateUserCommand(target_user_id=1, requester_user_id=1))
    port.email_exists.assert_not_called()


@pytest.mark.asyncio
async def test_email_exists_not_called_when_email_unchanged() -> None:
    """F11b — email same as existing → email_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    cmd = UpdateUserCommand(
        target_username="alice",
        requester_user_id=1,
        target_user_id=1,
        email="alice@example.com",  # same as _EXISTING.email
    )
    await use_case(cmd)
    port.email_exists.assert_not_called()


# ── F12: skip username_exists when username is None or unchanged ──────────────


@pytest.mark.asyncio
async def test_username_exists_not_called_when_username_is_none() -> None:
    """F12a — username=None → username_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    await use_case(UpdateUserCommand(target_user_id=1, requester_user_id=1))
    port.username_exists.assert_not_called()


@pytest.mark.asyncio
async def test_username_exists_not_called_when_username_unchanged() -> None:
    """F12b — username same as existing → username_exists not called."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    cmd = UpdateUserCommand(
        target_username="alice",
        requester_user_id=1,
        target_user_id=1,
        username="alice",  # same as _EXISTING.username
    )
    await use_case(cmd)
    port.username_exists.assert_not_called()


# ── F13: happy path ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_update_and_returns_result() -> None:
    """F13 — all checks pass → port.update called; UpdatedUserResult returned."""
    port = _make_port()
    use_case = UpdateUserUseCase(port=port)
    result = await use_case(_CMD)
    port.update.assert_called_once_with(_CMD)
    assert isinstance(result, UpdatedUserResult)
    assert result.message == "User updated"
