# FEATURE: list_posts — use-case unit tests.
#
# Covers F11: use case returns exactly what port.list() returns (no transformation).
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.features.posts._shared.entities import PostItem, PostPage
from app.features.posts.list_posts.domain.commands import ListPostsQuery
from app.features.posts.list_posts.domain.use_case import ListPostsUseCase

_QUERY = ListPostsQuery(username="alice", page=1, items_per_page=10)

_PAGE = PostPage(
    items=[
        PostItem(
            id=1,
            title="Hello",
            text="World",
            media_url=None,
            created_at=datetime(2024, 1, 1, tzinfo=UTC),
            created_by_user_id=1,
            username="alice",
            status="approved",
            post_uuid=uuid.UUID("00000000-0000-0000-0000-000000000001"),
        )
    ],
    total_count=1,
    page=1,
    items_per_page=10,
)


@pytest.mark.asyncio
async def test_use_case_returns_port_result_unchanged() -> None:
    port = MagicMock()
    port.list = AsyncMock(return_value=_PAGE)
    use_case = ListPostsUseCase(port=port)

    result = await use_case(_QUERY)

    assert result is _PAGE
    port.list.assert_called_once_with(_QUERY)
