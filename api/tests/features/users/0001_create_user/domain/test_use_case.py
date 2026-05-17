# FEATURE: create_user — use-case unit tests.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import DuplicateValueDomainError
from app.features.users.create_user.domain.commands import CreateUserCommand
from app.features.users.create_user.domain.entities import CreatedUser
from app.features.users.create_user.domain.use_case import CreateUserUseCase

_CMD = CreateUserCommand(
    name="Alice Example",
    username="alice99",
    email="alice99@example.com",
    password="Str0ng!pw",
)

_ENTITY = CreatedUser(
    id=1,
    name="Alice Example",
    username="alice99",
    email="alice99@example.com",
    profile_image_url="https://profileimageurl.com",
    tier_id=None,
)


def _make_use_case(*, email_exists: bool = False, username_exists: bool = False) -> CreateUserUseCase:
    port = MagicMock()
    port.email_exists = AsyncMock(return_value=email_exists)
    port.username_exists = AsyncMock(return_value=username_exists)
    port.create = AsyncMock(return_value=_ENTITY)
    return CreateUserUseCase(port=port, password_hasher=lambda p: f"hashed:{p}")


@pytest.mark.asyncio
async def test_happy_path_calls_create_and_returns_entity() -> None:
    use_case = _make_use_case()
    result = await use_case(_CMD)
    assert result == _ENTITY
    use_case._port.create.assert_called_once()


@pytest.mark.asyncio
async def test_happy_path_hashes_password() -> None:
    use_case = _make_use_case()
    await use_case(_CMD)
    internal = use_case._port.create.call_args[0][0]
    assert internal.hashed_password == "hashed:Str0ng!pw"
    assert not hasattr(internal, "password")


@pytest.mark.asyncio
async def test_duplicate_email_raises_before_create() -> None:
    use_case = _make_use_case(email_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Email is already registered"
    use_case._port.create.assert_not_called()


@pytest.mark.asyncio
async def test_duplicate_username_raises_before_create() -> None:
    use_case = _make_use_case(username_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Username not available"
    use_case._port.create.assert_not_called()


@pytest.mark.asyncio
async def test_email_checked_before_username() -> None:
    """Email existence is checked first; username check is skipped if email fails."""
    use_case = _make_use_case(email_exists=True, username_exists=True)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Email is already registered"
    use_case._port.username_exists.assert_not_called()
