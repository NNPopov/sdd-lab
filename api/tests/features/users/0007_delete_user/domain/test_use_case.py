# FEATURE: delete_user — use-case unit tests.
#
# Covers: F2, F3, F4.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.users.delete_user.domain.commands import DeleteUserCommand
from app.features.users.delete_user.domain.entities import DeleteUserResult, DeleteUserTarget
from app.features.users.delete_user.domain.use_case import DeleteUserUseCase

_TARGET = DeleteUserTarget(username="alice")
_CMD = DeleteUserCommand(target_username="alice", requester_username="alice")


def _make_port(*, target: DeleteUserTarget | None = _TARGET) -> MagicMock:
    port = MagicMock()
    port.get_by_username = AsyncMock(return_value=target)
    port.soft_delete = AsyncMock(return_value=None)
    return port


def _make_use_case(**kwargs: object) -> DeleteUserUseCase:
    return DeleteUserUseCase(port=_make_port(**kwargs))  # type: ignore[arg-type]


# ── F2: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_raises_when_port_returns_none() -> None:
    """F2 — get_by_username returns None → NotFoundDomainError."""
    use_case = _make_use_case(target=None)
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


# ── F3: forbidden — wrong owner ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_raised_when_requester_is_not_owner() -> None:
    """F3 — requester_username != target.username → ForbiddenDomainError; soft_delete not called."""
    cmd = DeleteUserCommand(target_username="alice", requester_username="bob")
    port = _make_port()
    use_case = DeleteUserUseCase(port=port)
    with pytest.raises(ForbiddenDomainError):
        await use_case(cmd)
    port.soft_delete.assert_not_called()


# ── F4: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_soft_delete_and_returns_result() -> None:
    """F4 — all checks pass → port.soft_delete called; DeleteUserResult returned."""
    port = _make_port()
    use_case = DeleteUserUseCase(port=port)
    result = await use_case(_CMD)
    port.soft_delete.assert_called_once_with("alice")
    assert isinstance(result, DeleteUserResult)
    assert result.message == "User deleted"
