# FEATURE: get_user_by_id — adapter unit tests.
import pytest
import pytest_asyncio

from app.adapters.db.models.user import User
from app.features.users.get_user_by_id.data.adapter import GetUserByIdAdapter
from app.features.users.get_user_by_id.domain.commands import GetUserByIdQuery


@pytest_asyncio.fixture()
async def active_user(adapter_session_factory):
    async with adapter_session_factory() as session:
        user = User(
            name="Bob Tester",
            username="bobtester",
            email="bob@example.com",
            hashed_password="hashed_pw",
            profile_image_url="https://profileimageurl.com",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user


@pytest_asyncio.fixture()
async def deleted_user(adapter_session_factory):
    async with adapter_session_factory() as session:
        user = User(
            name="Carol Deleted",
            username="caroldeleted",
            email="carol@example.com",
            hashed_password="hashed_pw",
            profile_image_url="https://profileimageurl.com",
            is_deleted=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user


@pytest.mark.asyncio
async def test_get_returns_found_user_for_active_row(adapter_session_factory, active_user) -> None:
    adapter = GetUserByIdAdapter(session_factory=adapter_session_factory)
    result = await adapter.get(GetUserByIdQuery(user_id=active_user.id))

    assert result is not None
    assert result.id == active_user.id
    assert result.name == "Bob Tester"
    assert result.username == "bobtester"
    assert result.email == "bob@example.com"
    assert result.profile_image_url == "https://profileimageurl.com"
    assert result.tier_id is None
    assert result.is_moderator is False


@pytest.mark.asyncio
async def test_get_returns_none_when_user_does_not_exist(adapter_session_factory) -> None:
    adapter = GetUserByIdAdapter(session_factory=adapter_session_factory)
    result = await adapter.get(GetUserByIdQuery(user_id=999_999))
    assert result is None


@pytest.mark.asyncio
async def test_get_returns_none_for_soft_deleted_user(adapter_session_factory, deleted_user) -> None:
    adapter = GetUserByIdAdapter(session_factory=adapter_session_factory)
    result = await adapter.get(GetUserByIdQuery(user_id=deleted_user.id))
    assert result is None
