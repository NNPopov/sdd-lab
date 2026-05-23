# FEATURE: update_tier — use-case unit tests.
#
# Covers: F6, F7, F8, F9, F10.
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import DuplicateValueDomainError, NotFoundDomainError
from app.features.tiers._shared.entities import TierItem
from app.features.tiers.update_tier.domain.commands import UpdateTierCommand
from app.features.tiers.update_tier.domain.use_case import UpdateTierUseCase

pytestmark = pytest.mark.asyncio

_TIER_ITEM = TierItem(id=1, name="silver", created_at=datetime(2025, 1, 1, tzinfo=UTC))
_CMD = UpdateTierCommand(name="silver", new_name="gold")


def _make_port(
    *,
    get_result: TierItem | None = _TIER_ITEM,
    update_side_effect: Exception | None = None,
) -> MagicMock:
    port = MagicMock()
    port.get = AsyncMock(return_value=get_result)
    if update_side_effect is not None:
        port.update = AsyncMock(side_effect=update_side_effect)
    else:
        port.update = AsyncMock(return_value=None)
    return port


# ── F6, F7: tier not found ────────────────────────────────────────────────────


async def test_not_found_raises_when_tier_missing() -> None:
    """F6, F7 — port.get returns None → NotFoundDomainError; port.update not called."""
    port = _make_port(get_result=None)
    use_case = UpdateTierUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "Tier not found"
    port.update.assert_not_called()


# ── F8, F9: happy path ────────────────────────────────────────────────────────


async def test_happy_path_calls_port_update_and_returns_none() -> None:
    """F8, F9 — port.get returns TierItem → port.update called; use-case returns None."""
    port = _make_port()
    use_case = UpdateTierUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)
    port.update.assert_called_once_with("silver", "gold")
    assert result is None


# ── F10: duplicate propagates unchanged ──────────────────────────────────────


async def test_duplicate_domain_error_propagates_from_port_update() -> None:
    """F10 — DuplicateValueDomainError from port.update propagates unchanged."""
    exc = DuplicateValueDomainError("Tier name already exists")
    port = _make_port(update_side_effect=exc)
    use_case = UpdateTierUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value is exc
