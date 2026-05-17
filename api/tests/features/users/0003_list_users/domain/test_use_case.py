# FEATURE: list_users — use-case unit tests.
#
# Covers F11: use case returns exactly what port.list() returns (no transformation).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.users.list_users.domain.commands import ListUsersQuery
from app.features.users.list_users.domain.entities import ListedUser, UserPage
from app.features.users.list_users.domain.use_case import ListUsersUseCase

_QUERY = ListUsersQuery(page=1, items_per_page=10)

_PAGE = UserPage(
    items=[
        ListedUser(
            id=1,
            name="Alice",
            username="alice",
            email="alice@example.com",
            profile_image_url="https://profileimageurl.com",
            tier_id=None,
        )
    ],
    total_count=1,
    page=1,
    items_per_page=10,
)


@pytest.mark.asyncio
async def test_use_case_returns_port_result_unchanged() -> None:
    port = MagicMock()
    port.list = AsyncMock(return_value=_PAGE)
    use_case = ListUsersUseCase(port=port)

    result = await use_case(_QUERY)

    assert result is _PAGE
    port.list.assert_called_once_with(_QUERY)
