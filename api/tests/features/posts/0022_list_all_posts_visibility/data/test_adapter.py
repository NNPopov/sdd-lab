# FEATURE: list_all_posts_visibility — adapter unit tests.
#
# Covers: F6  (total_count reflects filtered/unfiltered count)
#         F8  (status field populated on every returned PostItem)
#         F10 (requester_is_privileged flag drives filter decision)
#         F7  (empty PostPage when no approved posts, non-privileged caller)
#
# Uses a real async session against the test Postgres DB via the DI-overridden
# session factory. No mocks — the adapter SQL is exercised end-to-end.
import pytest

from app.features.posts.list_all_posts.data.adapter import ListAllPostsAdapter
from app.features.posts.list_all_posts.domain.commands import ListAllPostsQuery

pytestmark = pytest.mark.asyncio


async def test_non_privileged_receives_only_approved_posts(
    alice_user: dict,
    posts_data: list,
    async_client,
) -> None:
    """F10, F6: requester_is_privileged=False → only approved posts, total_count=1."""
    from app.bootstrap.container import container as _di_container

    adapter = ListAllPostsAdapter(session_factory=_di_container.session_factory())
    query = ListAllPostsQuery(page=1, items_per_page=10, requester_is_privileged=False)
    result = await adapter.list(query)

    assert result.total_count == 1
    assert len(result.items) == 1
    assert result.items[0].status == "approved"


async def test_privileged_receives_all_posts_regardless_of_status(
    alice_user: dict,
    posts_data: list,
    async_client,
) -> None:
    """F10, F6: requester_is_privileged=True → all posts returned, total_count=3."""
    from app.bootstrap.container import container as _di_container

    adapter = ListAllPostsAdapter(session_factory=_di_container.session_factory())
    query = ListAllPostsQuery(page=1, items_per_page=10, requester_is_privileged=True)
    result = await adapter.list(query)

    assert result.total_count == 3
    assert len(result.items) == 3
    statuses = {item.status for item in result.items}
    assert "approved" in statuses
    assert "pending_review" in statuses


async def test_status_field_populated_on_all_returned_items(
    alice_user: dict,
    posts_data: list,
    async_client,
) -> None:
    """F8: status is a non-empty string on every PostItem, privileged view."""
    from app.bootstrap.container import container as _di_container

    adapter = ListAllPostsAdapter(session_factory=_di_container.session_factory())
    query = ListAllPostsQuery(page=1, items_per_page=10, requester_is_privileged=True)
    result = await adapter.list(query)

    for item in result.items:
        assert isinstance(item.status, str)
        assert item.status != ""


async def test_empty_postpage_when_no_approved_posts_non_privileged(
    alice_user: dict,
    async_client,
) -> None:
    """F7: no approved posts exist, non-privileged caller → total_count==0, items==[]."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=alice_user["id"],
            title="Pending Only",
            text="This post is pending review.",
        )
        session.add(post)
        await session.commit()

    adapter = ListAllPostsAdapter(session_factory=_di_container.session_factory())
    query = ListAllPostsQuery(page=1, items_per_page=10, requester_is_privileged=False)
    result = await adapter.list(query)

    assert result.total_count == 0
    assert result.items == []
