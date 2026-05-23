# FEATURE: create_tier — use-case unit tests.
#
# Covers: F6 (use-case delegates only; no conditional logic).
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.tiers._shared.entities import TierItem
from app.features.tiers.create_tier.domain.commands import CreateTierCommand
from app.features.tiers.create_tier.domain.use_case import CreateTierUseCase

pytestmark = pytest.mark.asyncio

_CMD = CreateTierCommand(name="gold")
_TIER_ITEM = TierItem(id=1, name="gold", created_at=datetime(2025, 1, 1, tzinfo=UTC))


def _make_port(*, result: TierItem = _TIER_ITEM) -> MagicMock:
    port = MagicMock()
    port.create = AsyncMock(return_value=result)
    return port


async def test_use_case_calls_port_create_with_command() -> None:
    """F6 — use_case(command) delegates to port.create with the same command."""
    port = _make_port()
    use_case = CreateTierUseCase(port=port)  # type: ignore[arg-type]
    await use_case(_CMD)
    port.create.assert_called_once_with(_CMD)


async def test_use_case_returns_tier_item_from_port() -> None:
    """F6 — return value equals the TierItem returned by the mocked port."""
    port = _make_port()
    use_case = CreateTierUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)
    assert result == _TIER_ITEM
