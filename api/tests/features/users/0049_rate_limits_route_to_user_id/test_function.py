# FEATURE: rate_limits_route_to_user_id — function-level unit tests.
#
# read_user_rate_limits is a shallow aggregator free function (no port/adapter/
# use-case class), so the hexagonal use-case and adapter unit tests are opted
# out (see plan.md § 6). This file replaces them: it calls the function directly
# with patched repositories and a sentinel session.
#
# Covers: F2, F3, F4, F5, F6.
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.users.schemas import UserRead
from app.features.users.use_cases import user_rate_limits_get
from app.features.users.use_cases.user_rate_limits_get import read_user_rate_limits

pytestmark = pytest.mark.asyncio

_USER_WITH_TIER = {
    "id": 42,
    "name": "Target",
    "username": "target",
    "email": "target@example.com",
    "profile_image_url": "https://example.com/img.png",
    "tier_id": 7,
}
_USER_NO_TIER = {**_USER_WITH_TIER, "tier_id": None}


def _patch_repos(
    monkeypatch: pytest.MonkeyPatch,
    *,
    user: dict | None,
    tier: dict | None = None,
    rate_limits: list | None = None,
) -> dict[str, AsyncMock]:
    """Replace the three module-level repositories with AsyncMocks; return them."""
    users_get = AsyncMock(return_value=user)
    tiers_get = AsyncMock(return_value=tier)
    rate_limits_get_multi = AsyncMock(return_value={"data": rate_limits or [], "total_count": 0})
    monkeypatch.setattr(user_rate_limits_get.crud_users, "get", users_get)
    monkeypatch.setattr(user_rate_limits_get.crud_tiers, "get", tiers_get)
    monkeypatch.setattr(user_rate_limits_get.crud_rate_limits, "get_multi", rate_limits_get_multi)
    return {"users_get": users_get, "tiers_get": tiers_get, "rate_limits_get_multi": rate_limits_get_multi}


# ── F3: lookup is by integer id, not username ─────────────────────────────────


async def test_looks_user_up_by_id(monkeypatch: pytest.MonkeyPatch) -> None:
    """F3 — crud_users.get is awaited with id=user_id (not username=...)."""
    db = MagicMock()
    repos = _patch_repos(monkeypatch, user=_USER_NO_TIER)

    await read_user_rate_limits(MagicMock(), user_id=42, db=db)

    repos["users_get"].assert_awaited_once_with(db=db, id=42, schema_to_select=UserRead)
    _, kwargs = repos["users_get"].await_args
    assert "username" not in kwargs


# ── F4: user not found ────────────────────────────────────────────────────────


async def test_raises_when_user_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    """F4 — crud_users.get returns None → NotFoundDomainError('User not found')."""
    repos = _patch_repos(monkeypatch, user=None)

    with pytest.raises(NotFoundDomainError) as exc_info:
        await read_user_rate_limits(MagicMock(), user_id=999, db=MagicMock())

    assert exc_info.value.message == "User not found"
    repos["tiers_get"].assert_not_awaited()


# ── F2: user without a tier → empty rate limits, no tier/rate-limit queries ───


async def test_no_tier_returns_empty_list(monkeypatch: pytest.MonkeyPatch) -> None:
    """F2 — tier_id is None → tier_rate_limits == [] and tier/rate-limit repos not queried."""
    repos = _patch_repos(monkeypatch, user=_USER_NO_TIER)

    result = await read_user_rate_limits(MagicMock(), user_id=42, db=MagicMock())

    assert result["tier_rate_limits"] == []
    assert result["tier_id"] is None
    repos["tiers_get"].assert_not_awaited()
    repos["rate_limits_get_multi"].assert_not_awaited()


# ── F5: tier referenced but tier row absent ───────────────────────────────────


async def test_raises_when_tier_missing(monkeypatch: pytest.MonkeyPatch) -> None:
    """F5 — user has tier_id but crud_tiers.get returns None → NotFoundDomainError('Tier not found')."""
    repos = _patch_repos(monkeypatch, user=_USER_WITH_TIER, tier=None)

    with pytest.raises(NotFoundDomainError) as exc_info:
        await read_user_rate_limits(MagicMock(), user_id=42, db=MagicMock())

    assert exc_info.value.message == "Tier not found"
    repos["rate_limits_get_multi"].assert_not_awaited()


# ── F6: valid tier → tier_rate_limits is the repository's data payload ────────


async def test_valid_tier_returns_rate_limit_data(monkeypatch: pytest.MonkeyPatch) -> None:
    """F6 — tier_rate_limits equals crud_rate_limits.get_multi(...)['data']."""
    db = MagicMock()
    rate_rows = [{"id": 1, "name": "pro_login", "path": "login", "limit": 10, "period": 60}]
    repos = _patch_repos(
        monkeypatch,
        user=_USER_WITH_TIER,
        tier={"id": 7, "name": "pro"},
        rate_limits=rate_rows,
    )

    result = await read_user_rate_limits(MagicMock(), user_id=42, db=db)

    repos["rate_limits_get_multi"].assert_awaited_once_with(db=db, tier_id=7)
    assert result["tier_rate_limits"] == rate_rows
    assert result["id"] == 42
    assert result["tier_id"] == 7
