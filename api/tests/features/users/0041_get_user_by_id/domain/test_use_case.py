# FEATURE: get_user_by_id — use-case unit tests.
from unittest.mock import AsyncMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.users.get_user_by_id.domain.commands import GetUserByIdQuery
from app.features.users.get_user_by_id.domain.entities import FoundUser
from app.features.users.get_user_by_id.domain.ports.get_user_by_id_port import GetUserByIdPort
from app.features.users.get_user_by_id.domain.use_case import GetUserByIdUseCase

_QUERY = GetUserByIdQuery(user_id=1)

_ENTITY = FoundUser(
    id=1,
    name="Alice Example",
    username="alice99",
    email="alice99@example.com",
    profile_image_url="https://profileimageurl.com",
    tier_id=None,
    is_moderator=False,
)


def _make_use_case(*, found: FoundUser | None) -> GetUserByIdUseCase:
    port = AsyncMock(spec=GetUserByIdPort)
    port.get.return_value = found
    return GetUserByIdUseCase(port=port)


@pytest.mark.asyncio
async def test_returns_found_user_when_port_returns_entity() -> None:
    use_case = _make_use_case(found=_ENTITY)
    result = await use_case(_QUERY)
    assert result == _ENTITY


@pytest.mark.asyncio
async def test_raises_not_found_when_port_returns_none() -> None:
    use_case = _make_use_case(found=None)
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_QUERY)
    assert exc_info.value.message == "User not found"
