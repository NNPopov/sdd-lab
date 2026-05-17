# FEATURE: delete_db_user — use-case unit tests.
#
# Covers: F2, F3 (not-found → NotFoundDomainError), F4 (happy path).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.users.delete_db_user.domain.commands import DeleteDbUserCommand
from app.features.users.delete_db_user.domain.entities import DbDeleteUserTarget, DeleteDbUserResult
from app.features.users.delete_db_user.domain.use_case import DeleteDbUserUseCase

_TARGET = DbDeleteUserTarget(username="alice")
_CMD = DeleteDbUserCommand(target_username="alice")


def _make_port(*, target: DbDeleteUserTarget | None = _TARGET) -> MagicMock:
    port = MagicMock()
    port.get_by_username = AsyncMock(return_value=target)
    port.db_delete = AsyncMock(return_value=None)
    return port


# ── F2: user not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_raises_when_port_returns_none() -> None:
    """F2 — get_by_username returns None → NotFoundDomainError."""
    use_case = DeleteDbUserUseCase(port=_make_port(target=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"


@pytest.mark.asyncio
async def test_db_delete_not_called_when_user_not_found() -> None:
    """F2 — db_delete must not be called when user is absent."""
    port = _make_port(target=None)
    use_case = DeleteDbUserUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError):
        await use_case(_CMD)
    port.db_delete.assert_not_called()


# ── F3: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_calls_db_delete_and_returns_result() -> None:
    """F3 — user found → port.db_delete called; DeleteDbUserResult returned."""
    port = _make_port()
    use_case = DeleteDbUserUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)
    port.db_delete.assert_called_once_with("alice")
    assert isinstance(result, DeleteDbUserResult)
    assert result.message == "User deleted from the database"
