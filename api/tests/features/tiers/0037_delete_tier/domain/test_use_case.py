# FEATURE: delete_tier — use-case unit tests.
#
# Covers: F4, F5.
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.tiers._shared.entities import TierItem
from app.features.tiers.delete_tier.domain.commands import DeleteTierCommand
from app.features.tiers.delete_tier.domain.use_case import DeleteTierUseCase

pytestmark = pytest.mark.asyncio

_TIER_ITEM = TierItem(id=1, name="silver", created_at=datetime(2025, 1, 1, tzinfo=UTC))
_CMD = DeleteTierCommand(id=1)


def _make_port(*, get_result: TierItem | None = _TIER_ITEM) -> MagicMock:
    port = MagicMock()
    port.get = AsyncMock(return_value=get_result)
    port.delete = AsyncMock(return_value=None)
    return port


# ── F4: tier not found ────────────────────────────────────────────────────────


async def test_not_found_raises_and_delete_not_called() -> None:
    """F4 — port.get returns None → NotFoundDomainError; port.delete never called."""
    port = _make_port(get_result=None)
    use_case = DeleteTierUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Tier not found"
    port.delete.assert_not_called()


# ── F5: happy path ────────────────────────────────────────────────────────────


async def test_happy_path_calls_delete_and_returns_none() -> None:
    """F5 — port.get returns TierItem → port.delete called with id; use-case returns None."""
    port = _make_port()
    use_case = DeleteTierUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)
    port.get.assert_called_once_with(1)
    port.delete.assert_called_once_with(1)
    assert result is None
