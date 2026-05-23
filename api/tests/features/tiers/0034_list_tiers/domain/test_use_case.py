# FEATURE: list_tiers — use-case unit tests.
#
# Covers F8: use case returns exactly what port.list() returns (no transformation).
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.tiers._shared.entities import TierItem, TierPage
from app.features.tiers.list_tiers.domain.commands import ListTiersQuery
from app.features.tiers.list_tiers.domain.use_case import ListTiersUseCase

_QUERY = ListTiersQuery(page=1, items_per_page=10)

_PAGE = TierPage(
    items=[
        TierItem(id=1, name="free", created_at=datetime(2024, 1, 1, tzinfo=UTC)),
        TierItem(id=2, name="pro", created_at=datetime(2024, 1, 2, tzinfo=UTC)),
    ],
    total_count=2,
    page=1,
    items_per_page=10,
)


@pytest.mark.asyncio
async def test_use_case_returns_port_result_unchanged() -> None:
    port = MagicMock()
    port.list = AsyncMock(return_value=_PAGE)
    use_case = ListTiersUseCase(port=port)

    result = await use_case(_QUERY)

    assert result is _PAGE
    port.list.assert_called_once_with(_QUERY)
