# FEATURE: update_user_tier_route_to_user_id — function-level unit tests.
#
# patch_user_tier is a shallow aggregator free function (no port/adapter/
# use-case class), so the hexagonal use-case and adapter unit tests are opted
# out (see plan.md § 6). This file replaces them: it calls the function directly
# with patched repositories and a sentinel session.
#
# Covers: F2, F3, F4, F5, F6.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.tiers.schemas import TierRead
from app.features.users.schemas import UserRead
from app.features.users.use_cases import user_tier_patch
from app.features.users.use_cases.user_tier_patch import patch_user_tier

pytestmark = pytest.mark.asyncio

_USER = {
    "id": 42,
    "name": "Target",
    "username": "target",
    "email": "target@example.com",
    "profile_image_url": "https://example.com/img.png",
    "tier_id": None,
}


def _patch_repos(
    monkeypatch: pytest.MonkeyPatch,
    *,
    user: dict | None,
    tier: dict | None = None,
) -> dict[str, AsyncMock]:
    """Replace the two module-level repositories with AsyncMocks; return them."""
    users_get = AsyncMock(return_value=user)
    tiers_get = AsyncMock(return_value=tier)
    users_update = AsyncMock(return_value=None)
    monkeypatch.setattr(user_tier_patch.crud_users, "get", users_get)
    monkeypatch.setattr(user_tier_patch.crud_tiers, "get", tiers_get)
    monkeypatch.setattr(user_tier_patch.crud_users, "update", users_update)
    return {"users_get": users_get, "tiers_get": tiers_get, "users_update": users_update}


# ── F2: user lookup is by integer id, not username ────────────────────────────


async def test_looks_user_up_by_id(monkeypatch: pytest.MonkeyPatch) -> None:
    """F2 — crud_users.get is awaited with id=user_id (not username=...)."""
    db = MagicMock()
    values = MagicMock(tier_id=7)
    repos = _patch_repos(monkeypatch, user=_USER, tier={"id": 7, "name": "pro"})

    await patch_user_tier(MagicMock(), user_id=42, values=values, db=db)

    repos["users_get"].assert_awaited_once_with(db=db, id=42, schema_to_select=UserRead)
    _, kwargs = repos["users_get"].await_args
    assert "username" not in kwargs


# ── F3: update is keyed by integer id, not username ───────────────────────────


async def test_updates_user_by_id(monkeypatch: pytest.MonkeyPatch) -> None:
    """F3 — crud_users.update is awaited with id=user_id (not username=...)."""
    db = MagicMock()
    values = MagicMock(tier_id=7)
    values.model_dump.return_value = {"tier_id": 7}
    repos = _patch_repos(monkeypatch, user=_USER, tier={"id": 7, "name": "pro"})

    await patch_user_tier(MagicMock(), user_id=42, values=values, db=db)

    repos["users_update"].assert_awaited_once_with(db=db, object={"tier_id": 7}, id=42)
    _, kwargs = repos["users_update"].await_args
    assert "username" not in kwargs


# ── F4: user not found → NotFoundDomainError, no update ───────────────────────


async def test_raises_when_user_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    """F4 — crud_users.get returns None → NotFoundDomainError('User not found'), no update."""
    values = MagicMock(tier_id=7)
    repos = _patch_repos(monkeypatch, user=None)

    with pytest.raises(NotFoundDomainError) as exc_info:
        await patch_user_tier(MagicMock(), user_id=999, values=values, db=MagicMock())

    assert exc_info.value.message == "User not found"
    repos["tiers_get"].assert_not_awaited()
    repos["users_update"].assert_not_awaited()


# ── F5: tier not found → NotFoundDomainError, no update ───────────────────────


async def test_raises_when_tier_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    """F5 — crud_tiers.get returns None → NotFoundDomainError('Tier not found'), no update."""
    db = MagicMock()
    values = MagicMock(tier_id=999)
    repos = _patch_repos(monkeypatch, user=_USER, tier=None)

    with pytest.raises(NotFoundDomainError) as exc_info:
        await patch_user_tier(MagicMock(), user_id=42, values=values, db=db)

    assert exc_info.value.message == "Tier not found"
    repos["tiers_get"].assert_awaited_once_with(db=db, id=999, schema_to_select=TierRead)
    repos["users_update"].assert_not_awaited()


# ── F6: happy path → success message with the user's name ─────────────────────


async def test_happy_path_returns_success_message(monkeypatch: pytest.MonkeyPatch) -> None:
    """F6 — both found → returns {'message': 'User <name> Tier updated'}."""
    db = MagicMock()
    values = MagicMock(tier_id=7)
    values.model_dump.return_value = {"tier_id": 7}
    _patch_repos(monkeypatch, user=_USER, tier={"id": 7, "name": "pro"})

    result = await patch_user_tier(MagicMock(), user_id=42, values=values, db=db)

    assert result == {"message": "User Target Tier updated"}
