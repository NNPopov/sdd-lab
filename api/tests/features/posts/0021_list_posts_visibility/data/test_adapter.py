# FEATURE: list_posts_visibility — adapter unit tests.
#
# Covers: F8 (visibility filter for non-author and unauthenticated callers)
#         F9 (no filter applied when caller is the author)
#         F10 (status field populated on every returned PostItem)
#         F4  (empty PostPage when no approved posts, non-author caller)
#
# Uses a real async session against the test Postgres DB via the DI-overridden
# session factory. No mocks — the adapter SQL is exercised end-to-end.
import pytest

from app.features.posts.list_posts.data.adapter import ListPostsAdapter
from app.features.posts.list_posts.domain.commands import ListPostsQuery

pytestmark = pytest.mark.asyncio


async def test_author_receives_all_posts_regardless_of_status(
    alice_user: dict,
    alice_posts: list,
    async_client,
) -> None:
    """F9: requester_user_id == user_id → all posts returned regardless of status."""
    from app.bootstrap.container import container as _di_container

    adapter = ListPostsAdapter(session_factory=_di_container.session_factory())
    query = ListPostsQuery(
        user_id=alice_user["id"],
        page=1,
        items_per_page=10,
        requester_user_id=alice_user["id"],
    )
    result = await adapter.list(query)

    assert result.total_count == 3
    assert len(result.items) == 3
    statuses = {item.status for item in result.items}
    assert "approved" in statuses
    assert "pending_review" in statuses


async def test_non_author_receives_only_approved_posts(
    alice_user: dict,
    bob_user: dict,
    alice_posts: list,
    async_client,
) -> None:
    """F8: requester_user_id != user_id → only approved posts returned."""
    from app.bootstrap.container import container as _di_container

    adapter = ListPostsAdapter(session_factory=_di_container.session_factory())
    query = ListPostsQuery(
        user_id=alice_user["id"],
        page=1,
        items_per_page=10,
        requester_user_id=bob_user["id"],
    )
    result = await adapter.list(query)

    assert result.total_count == 1
    assert len(result.items) == 1
    assert result.items[0].status == "approved"


async def test_unauthenticated_receives_only_approved_posts(
    alice_user: dict,
    alice_posts: list,
    async_client,
) -> None:
    """F8: requester_user_id is None → only approved posts returned."""
    from app.bootstrap.container import container as _di_container

    adapter = ListPostsAdapter(session_factory=_di_container.session_factory())
    query = ListPostsQuery(
        user_id=alice_user["id"],
        page=1,
        items_per_page=10,
        requester_user_id=None,
    )
    result = await adapter.list(query)

    assert result.total_count == 1
    assert len(result.items) == 1
    assert result.items[0].status == "approved"


async def test_status_field_populated_on_all_returned_items(
    alice_user: dict,
    alice_posts: list,
    async_client,
) -> None:
    """F10: status field is a non-empty string on every returned PostItem."""
    from app.bootstrap.container import container as _di_container

    adapter = ListPostsAdapter(session_factory=_di_container.session_factory())
    query = ListPostsQuery(
        user_id=alice_user["id"],
        page=1,
        items_per_page=10,
        requester_user_id=alice_user["id"],  # author — all posts returned
    )
    result = await adapter.list(query)

    for item in result.items:
        assert isinstance(item.status, str)
        assert item.status != ""


async def test_empty_postpage_when_no_approved_posts_for_non_author(
    alice_user: dict,
    async_client,
) -> None:
    """F4 (adapter): no approved posts, non-author caller → total_count==0, items==[]."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=alice_user["id"],
            title="Pending Post",
            text="This post is pending review.",
        )
        session.add(post)
        await session.commit()

    adapter = ListPostsAdapter(session_factory=_di_container.session_factory())
    query = ListPostsQuery(
        user_id=alice_user["id"],
        page=1,
        items_per_page=10,
        requester_user_id=None,
    )
    result = await adapter.list(query)

    assert result.total_count == 0
    assert result.items == []
