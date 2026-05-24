# FEATURE: delete_user — use-case unit tests.
#
# Covers: F5, F6, F7, F8.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.users.delete_user.domain.commands import DeleteUserCommand
from app.features.users.delete_user.domain.entities import DeleteUserResult, DeleteUserTarget
from app.features.users.delete_user.domain.use_case import DeleteUserUseCase

_TARGET = DeleteUserTarget(id=1)
_CMD = DeleteUserCommand(target_user_id=1, requester_user_id=1)


def _make_port(*, target: DeleteUserTarget | None = _TARGET) -> MagicMock:
    port = MagicMock()
    port.get_by_id = AsyncMock(return_value=target)
    port.soft_delete = AsyncMock(return_value=None)
    return port


def _make_use_case(**kwargs: object) -> DeleteUserUseCase:
    return DeleteUserUseCase(port=_make_port(**kwargs))  # type: ignore[arg-type]


# ── F5: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_raises_when_port_returns_none() -> None:
    """F5 — get_by_id returns None → NotFoundDomainError."""
    use_case = _make_use_case(target=None)
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F6, F8: forbidden — wrong owner ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_raised_when_requester_is_not_owner() -> None:
    """F6 — requester_user_id != target.id → ForbiddenDomainError; soft_delete not called."""
    cmd = DeleteUserCommand(target_user_id=1, requester_user_id=2)
    port = _make_port()
    use_case = DeleteUserUseCase(port=port)
    with pytest.raises(ForbiddenDomainError):
        await use_case(cmd)
    port.soft_delete.assert_not_called()


# ── F7: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_soft_delete_and_returns_result() -> None:
    """F7 — all checks pass → port.soft_delete called with target_user_id; DeleteUserResult returned."""
    port = _make_port()
    use_case = DeleteUserUseCase(port=port)
    result = await use_case(_CMD)
    port.soft_delete.assert_called_once_with(1)
    assert isinstance(result, DeleteUserResult)
    assert result.message == "User deleted"
