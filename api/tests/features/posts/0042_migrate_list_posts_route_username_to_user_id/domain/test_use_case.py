# FEATURE: migrate_list_posts_route_username_to_user_id — use-case unit tests.
#
# Covers F14 (ListPostsQuery now exposes user_id / requester_user_id) and
# F16 (the use-case forwards the query — including requester_user_id — to the
# port unchanged and returns the port's PostPage unchanged; it is a pure
# pass-through with no username/user_id logic of its own).
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock

import pytest

from app.features.posts._shared.entities import PostItem, PostPage
from app.features.posts.list_posts.domain.commands import ListPostsQuery
from app.features.posts.list_posts.domain.ports.list_posts_port import ListPostsPort
from app.features.posts.list_posts.domain.use_case import ListPostsUseCase


def _make_page(user_id: int) -> PostPage:
    return PostPage(
        items=[
            PostItem(
                id=1,
                title="Hello",
                text="World",
                media_url=None,
                created_at=datetime(2024, 1, 1, tzinfo=UTC),
                created_by_user_id=user_id,
                username="alicepost",
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
    """The use-case returns exactly what port.list() returns, with no transformation."""
    page = _make_page(user_id=7)
    port = AsyncMock(spec=ListPostsPort)
    port.list.return_value = page
    use_case = ListPostsUseCase(port=port)

    query = ListPostsQuery(user_id=7, page=1, items_per_page=10)
    result = await use_case(query)

    assert result is page
    port.list.assert_awaited_once_with(query)


@pytest.mark.asyncio
async def test_use_case_forwards_author_query_unchanged() -> None:
    """Author view: requester_user_id == user_id is forwarded verbatim to the port."""
    port = AsyncMock(spec=ListPostsPort)
    port.list.return_value = _make_page(user_id=7)
    use_case = ListPostsUseCase(port=port)

    query = ListPostsQuery(user_id=7, page=1, items_per_page=10, requester_user_id=7)
    await use_case(query)

    forwarded = port.list.await_args.args[0]
    assert forwarded.user_id == 7
    assert forwarded.requester_user_id == 7


@pytest.mark.asyncio
async def test_use_case_forwards_public_query_unchanged() -> None:
    """Public view: requester_user_id is None is forwarded verbatim to the port."""
    port = AsyncMock(spec=ListPostsPort)
    port.list.return_value = _make_page(user_id=7)
    use_case = ListPostsUseCase(port=port)

    query = ListPostsQuery(user_id=7, page=1, items_per_page=10, requester_user_id=None)
    await use_case(query)

    forwarded = port.list.await_args.args[0]
    assert forwarded.user_id == 7
    assert forwarded.requester_user_id is None
