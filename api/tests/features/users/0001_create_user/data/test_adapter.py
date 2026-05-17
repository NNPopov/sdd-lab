# FEATURE: create_user — adapter unit tests.
from unittest.mock import AsyncMock, MagicMock

import pytest
from sqlalchemy.exc import IntegrityError

from app.domain.errors import DuplicateValueDomainError
from app.features.users.create_user.data.adapter import CreateUserAdapter
from app.features.users.create_user.domain.commands import CreateUserInternalCommand

_CMD = CreateUserInternalCommand(
    name="Alice Example",
    username="alice99",
    email="alice99@example.com",
    hashed_password="hashed_pw",
)


def _make_adapter(session_mock: MagicMock) -> CreateUserAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return CreateUserAdapter(session_factory=factory)


@pytest.mark.asyncio
async def test_email_exists_returns_true_when_row_found() -> None:
    session = MagicMock()
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = object()
    session.execute = AsyncMock(return_value=result_mock)
    adapter = _make_adapter(session)
    assert await adapter.email_exists("alice99@example.com") is True


@pytest.mark.asyncio
async def test_email_exists_returns_false_when_no_row() -> None:
    session = MagicMock()
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result_mock)
    adapter = _make_adapter(session)
    assert await adapter.email_exists("alice99@example.com") is False


@pytest.mark.asyncio
async def test_username_exists_returns_true_when_row_found() -> None:
    session = MagicMock()
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = object()
    session.execute = AsyncMock(return_value=result_mock)
    adapter = _make_adapter(session)
    assert await adapter.username_exists("alice99") is True


@pytest.mark.asyncio
async def test_username_exists_returns_false_when_no_row() -> None:
    session = MagicMock()
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result_mock)
    adapter = _make_adapter(session)
    assert await adapter.username_exists("alice99") is False


@pytest.mark.asyncio
async def test_create_integrity_error_maps_to_duplicate_value() -> None:
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock(side_effect=IntegrityError("dup", {}, None))
    adapter = _make_adapter(session)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await adapter.create(_CMD)
    assert "already registered" in exc_info.value.message
