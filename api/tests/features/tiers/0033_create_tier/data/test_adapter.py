# FEATURE: create_tier — adapter unit tests (real test Postgres).
#
# Covers: F5, F9.
from datetime import datetime

import pytest
from sqlalchemy.exc import OperationalError

from app.features.tiers._shared.entities import TierItem
from app.features.tiers.create_tier.data.adapter import CreateTierAdapter
from app.features.tiers.create_tier.domain.commands import CreateTierCommand

pytestmark = pytest.mark.asyncio


def _make_adapter() -> CreateTierAdapter:
    from app.bootstrap.container import container as _di_container

    return CreateTierAdapter(session_factory=_di_container.session_factory())


async def test_create_returns_tier_item_with_correct_fields() -> None:
    """F9 — create inserts tier and returns TierItem with correct name, non-null id and created_at."""
    adapter = _make_adapter()
    result = await adapter.create(CreateTierCommand(name="platinum_test_unique"))

    assert isinstance(result, TierItem)
    assert result.name == "platinum_test_unique"
    assert isinstance(result.id, int) and result.id > 0
    assert isinstance(result.created_at, datetime)


async def test_create_duplicate_raises_duplicate_value_domain_error() -> None:
    """F5 — inserting a duplicate name raises DuplicateValueDomainError."""
    from app.domain.errors import DuplicateValueDomainError

    adapter = _make_adapter()
    await adapter.create(CreateTierCommand(name="duplicate_tier_test"))
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await adapter.create(CreateTierCommand(name="duplicate_tier_test"))
    assert exc_info.value.message == "Tier name already exists"


async def test_create_unexpected_error_propagates_unchanged() -> None:
    """Adapter does not catch OperationalError — it propagates to the global handler."""
    from unittest.mock import AsyncMock, MagicMock

    adapter = _make_adapter()
    mock_session = MagicMock()
    mock_session.__aenter__ = AsyncMock(return_value=mock_session)
    mock_session.__aexit__ = AsyncMock(return_value=False)
    mock_session.add = MagicMock()
    mock_session.commit = AsyncMock(side_effect=OperationalError("db down", None, None))

    mock_factory = MagicMock(return_value=mock_session)
    adapter._session_factory = mock_factory

    with pytest.raises(OperationalError):
        await adapter.create(CreateTierCommand(name="any"))
