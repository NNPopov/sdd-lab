# FEATURE: assign_moderator — adapter unit tests.
#
# Covers: F8 (get_by_username not found), F9 (get_by_username found, soft-deleted excluded),
#         F10, F11, F12 (assign happy path).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.users.assign_moderator.data.adapter import AssignModeratorAdapter
from app.features.users.assign_moderator.domain.entities import AssignedUser


def _make_adapter(session_mock: MagicMock) -> AssignModeratorAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return AssignModeratorAdapter(session_factory=factory)


def _make_user_row(**kwargs: object) -> MagicMock:
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.id = kwargs.get("id", 1)
    row.name = kwargs.get("name", "Alice")
    row.username = kwargs.get("username", "alice")
    row.email = kwargs.get("email", "alice@example.com")
    row.profile_image_url = kwargs.get("profile_image_url", "https://example.com/img.png")
    row.tier_id = kwargs.get("tier_id", None)
    row.is_moderator = kwargs.get("is_moderator", False)
    row.is_deleted = kwargs.get("is_deleted", False)
    return row


# ── F8: get_by_username — not found ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_username_returns_none_when_no_row() -> None:
    """F8 — no active row matching username → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_username("ghost") is None


# ── F9: get_by_username — active row found ────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_username_returns_entity_for_active_row() -> None:
    """F9 — active row found → AssignedUser with all fields populated."""
    row = _make_user_row(id=7, name="Bob", username="bob", email="bob@example.com", tier_id=2)
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    entity = await _make_adapter(session).get_by_username("bob")

    assert isinstance(entity, AssignedUser)
    assert entity.id == 7
    assert entity.name == "Bob"
    assert entity.username == "bob"
    assert entity.email == "bob@example.com"
    assert entity.tier_id == 2
    assert entity.is_moderator is False


@pytest.mark.asyncio
async def test_get_by_username_excludes_soft_deleted_row() -> None:
    """F8/F9 — soft-deleted row filtered by WHERE is_deleted=False at query level."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_username("deleted_user") is None


# ── F10, F11, F12: assign happy path ─────────────────────────────────────────


@pytest.mark.asyncio
async def test_assign_returns_updated_entity() -> None:
    """F10, F11, F12 — assign writes is_moderator=True and returns the updated AssignedUser."""
    updated_row = _make_user_row(id=5, username="alice", is_moderator=True)

    execute_results = [MagicMock(), MagicMock()]
    execute_results[1].scalar_one.return_value = updated_row

    session = MagicMock()
    session.execute = AsyncMock(side_effect=execute_results)
    session.commit = AsyncMock()

    entity = await _make_adapter(session).assign("alice", granted_by_user_id=99)

    assert isinstance(entity, AssignedUser)
    assert entity.is_moderator is True
    assert entity.id == 5
    assert entity.username == "alice"
    session.commit.assert_called_once()
