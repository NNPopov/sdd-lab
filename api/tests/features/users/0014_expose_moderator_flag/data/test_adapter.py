# FEATURE: expose_moderator_flag — adapter unit tests.
#
# Covers: F1, F2, F12 (see requirements.md).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.users.get_user_by_username.data.adapter import GetUserByUsernameAdapter
from app.features.users.get_user_by_username.domain.commands import GetUserByUsernameQuery
from app.features.users.get_user_by_username.domain.entities import FoundUser
from app.features.users.get_user_by_username.domain.ports.get_user_by_username_port import GetUserByUsernamePort

_QUERY = GetUserByUsernameQuery(username="alicetester")


def _make_row(*, is_moderator: bool) -> MagicMock:
    row = MagicMock()
    row.id = 1
    row.name = "Alice Tester"
    row.username = "alicetester"
    row.email = "alice@example.com"
    row.profile_image_url = "https://www.profileimageurl.com"
    row.tier_id = None
    row.is_moderator = is_moderator
    return row


def _make_adapter(row: MagicMock | None) -> GetUserByUsernameAdapter:
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = row

    session = MagicMock()
    session.execute = AsyncMock(return_value=result_mock)

    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)

    return GetUserByUsernameAdapter(session_factory=factory)


def test_adapter_is_instance_of_port() -> None:
    """F1: adapter satisfies the port Protocol."""
    adapter = GetUserByUsernameAdapter(session_factory=MagicMock())
    assert isinstance(adapter, GetUserByUsernamePort)


@pytest.mark.asyncio
async def test_non_moderator_row_maps_is_moderator_false() -> None:
    """F2: row.is_moderator=False → FoundUser.is_moderator is False."""
    adapter = _make_adapter(_make_row(is_moderator=False))

    result = await adapter.get(_QUERY)

    assert isinstance(result, FoundUser)
    assert result.is_moderator is False


@pytest.mark.asyncio
async def test_moderator_row_maps_is_moderator_true() -> None:
    """F2: row.is_moderator=True → FoundUser.is_moderator is True."""
    adapter = _make_adapter(_make_row(is_moderator=True))

    result = await adapter.get(_QUERY)

    assert isinstance(result, FoundUser)
    assert result.is_moderator is True


@pytest.mark.asyncio
async def test_missing_user_returns_none() -> None:
    """Adapter returns None when no row matches the username."""
    adapter = _make_adapter(None)

    result = await adapter.get(_QUERY)

    assert result is None
