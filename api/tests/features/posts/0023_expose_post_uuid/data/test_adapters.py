# FEATURE: expose_post_uuid — adapter unit tests.
#
# Covers: F6 (ListPostsAdapter populates post_uuid from Post.uuid)
#         F7 (ListAllPostsAdapter populates post_uuid from Post.uuid)
#
# Uses a real async session against the test Postgres DB. No mocks.
import pytest
from httpx import AsyncClient

from app.features.posts.list_all_posts.data.adapter import ListAllPostsAdapter
from app.features.posts.list_all_posts.domain.commands import ListAllPostsQuery
from app.features.posts.list_posts.data.adapter import ListPostsAdapter
from app.features.posts.list_posts.domain.commands import ListPostsQuery

pytestmark = pytest.mark.asyncio


async def _seed_approved_post(session_factory, user_id: int) -> dict:
    """Insert one approved Post row via ORM; return its id and uuid as strings."""
    from app.adapters.db.models.post import Post

    async with session_factory() as session:
        post = Post(
            created_by_user_id=user_id,
            title="UUID Adapter Test",
            text="Checking post_uuid propagation in adapters.",
            status="approved",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        return {"id": post.id, "uuid": str(post.uuid)}


async def test_list_posts_adapter_populates_post_uuid(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F6: ListPostsAdapter.list() returns PostItem objects with post_uuid from Post.uuid."""
    from app.bootstrap.container import container as _di_container

    session_factory = _di_container.session_factory()
    seeded = await _seed_approved_post(session_factory, seeded_alice["id"])

    adapter = ListPostsAdapter(session_factory=session_factory)
    query = ListPostsQuery(
        username=seeded_alice["username"],
        requester_username=seeded_alice["username"],
        page=1,
        items_per_page=10,
    )
    result = await adapter.list(query)

    assert result.total_count >= 1
    item = next(i for i in result.items if i.id == seeded["id"])
    assert str(item.post_uuid) == seeded["uuid"]


async def test_list_all_posts_adapter_populates_post_uuid(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F7: ListAllPostsAdapter.list() returns PostItem objects with post_uuid from Post.uuid."""
    from app.bootstrap.container import container as _di_container

    session_factory = _di_container.session_factory()
    seeded = await _seed_approved_post(session_factory, seeded_alice["id"])

    adapter = ListAllPostsAdapter(session_factory=session_factory)
    query = ListAllPostsQuery(page=1, items_per_page=10, requester_is_privileged=False)
    result = await adapter.list(query)

    assert result.total_count >= 1
    item = next(i for i in result.items if i.id == seeded["id"])
    assert str(item.post_uuid) == seeded["uuid"]
