# FEATURE: get_tier — use-case unit tests.
#
# Covers: F5 (happy path: port returns TierItem), F6 (not-found: port returns None).
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.tiers._shared.entities import TierItem
from app.features.tiers.get_tier.domain.commands import GetTierQuery
from app.features.tiers.get_tier.domain.use_case import GetTierUseCase

pytestmark = pytest.mark.asyncio

_QUERY = GetTierQuery(name="gold")
_TIER_ITEM = TierItem(id=1, name="gold", created_at=datetime(2025, 1, 1, tzinfo=UTC))


def _make_port(*, result: TierItem | None = _TIER_ITEM) -> MagicMock:
    port = MagicMock()
    port.get = AsyncMock(return_value=result)
    return port


async def test_use_case_returns_tier_item_when_port_returns_one() -> None:
    """F5 — port.get returns TierItem; use_case returns it unchanged."""
    port = _make_port(result=_TIER_ITEM)
    use_case = GetTierUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_QUERY)
    assert result == _TIER_ITEM
    port.get.assert_called_once_with(_QUERY)


async def test_use_case_raises_not_found_when_port_returns_none() -> None:
    """F6 — port.get returns None; use_case raises NotFoundDomainError."""
    port = _make_port(result=None)
    use_case = GetTierUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_QUERY)
    assert exc_info.value.message == "Tier not found"
