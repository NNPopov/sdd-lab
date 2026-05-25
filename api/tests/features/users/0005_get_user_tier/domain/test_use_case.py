# FEATURE: get_user_tier — use-case unit tests.
#
# Covers: F6 (UserNotFound → 404), F7 (TierNotFound → 404),
#         F8 (None passthrough), F9 (FoundUserTier passthrough).
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.users.get_user_tier.domain.commands import GetUserTierQuery
from app.features.users.get_user_tier.domain.entities import (
    FoundUserTier,
    TierNotFound,
    UserNotFound,
)
from app.features.users.get_user_tier.domain.use_case import GetUserTierUseCase

_QUERY = GetUserTierQuery(user_id=42)

_FOUND_TIER = FoundUserTier(
    tier_id=7,
    tier_name="pro",
    tier_created_at=datetime(2024, 1, 1, tzinfo=UTC),
)


def _make_use_case(port_return_value: object) -> GetUserTierUseCase:
    port = MagicMock()
    port.get = AsyncMock(return_value=port_return_value)
    return GetUserTierUseCase(port=port)


# ── F9: FoundUserTier passes through unchanged ────────────────────────────────


@pytest.mark.asyncio
async def test_returns_found_user_tier_unchanged() -> None:
    use_case = _make_use_case(_FOUND_TIER)

    result = await use_case(_QUERY)

    assert result is _FOUND_TIER


# ── F8: None passes through (user has no tier) ────────────────────────────────


@pytest.mark.asyncio
async def test_returns_none_when_port_returns_none() -> None:
    use_case = _make_use_case(None)

    result = await use_case(_QUERY)

    assert result is None


# ── F6: UserNotFound → NotFoundDomainError("User not found") ─────────────────


@pytest.mark.asyncio
async def test_raises_not_found_for_user_not_found() -> None:
    use_case = _make_use_case(UserNotFound())

    with pytest.raises(NotFoundDomainError, match="User not found"):
        await use_case(_QUERY)


# ── F7: TierNotFound → NotFoundDomainError("Tier not found") ─────────────────


@pytest.mark.asyncio
async def test_raises_not_found_for_tier_not_found() -> None:
    use_case = _make_use_case(TierNotFound())

    with pytest.raises(NotFoundDomainError, match="Tier not found"):
        await use_case(_QUERY)
