# FEATURE: revoke_moderator — adapter unit tests.
#
# Covers: F9 (get_by_username not found), F10, F11 (get_by_username found, soft-deleted excluded),
#         F7, F8 (revoke happy path).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.users.revoke_moderator.data.adapter import RevokeModeratorAdapter
from app.features.users.revoke_moderator.domain.entities import RevokedUser


def _make_adapter(session_mock: MagicMock) -> RevokeModeratorAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return RevokeModeratorAdapter(session_factory=factory)


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


# ── F9: get_by_username — not found ──────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_username_returns_none_when_no_row() -> None:
    """F9 — no active row matching username → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_username("ghost") is None


# ── F10, F11: get_by_username — active row found / soft-deleted excluded ──────


@pytest.mark.asyncio
async def test_get_by_username_returns_entity_for_active_row() -> None:
    """F10 — active row found → RevokedUser with all fields populated."""
    row = _make_user_row(id=7, name="Bob", username="bob", email="bob@example.com", tier_id=2, is_moderator=True)
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    entity = await _make_adapter(session).get_by_username("bob")

    assert isinstance(entity, RevokedUser)
    assert entity.id == 7
    assert entity.name == "Bob"
    assert entity.username == "bob"
    assert entity.email == "bob@example.com"
    assert entity.tier_id == 2
    assert entity.is_moderator is True


@pytest.mark.asyncio
async def test_get_by_username_excludes_soft_deleted_row() -> None:
    """F11 — soft-deleted row filtered by WHERE is_deleted=False at query level → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    assert await _make_adapter(session).get_by_username("deleted_user") is None


# ── F7, F8: revoke happy path ─────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_revoke_returns_updated_entity() -> None:
    """F7, F8 — revoke writes is_moderator=False and returns the updated RevokedUser."""
    updated_row = _make_user_row(id=5, username="alice", is_moderator=False)

    execute_results = [MagicMock(), MagicMock()]
    execute_results[1].scalar_one.return_value = updated_row

    session = MagicMock()
    session.execute = AsyncMock(side_effect=execute_results)
    session.commit = AsyncMock()

    entity = await _make_adapter(session).revoke("alice")

    assert isinstance(entity, RevokedUser)
    assert entity.is_moderator is False
    assert entity.id == 5
    assert entity.username == "alice"
    session.commit.assert_called_once()
