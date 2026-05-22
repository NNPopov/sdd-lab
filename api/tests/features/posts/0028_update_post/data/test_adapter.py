# FEATURE: update_post — adapter unit tests (real test Postgres).
#
# Covers: F8, F9.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

from app.features.posts._shared.entities import PostItem
from app.features.posts.update_post.data.adapter import UpdatePostAdapter

pytestmark = pytest.mark.asyncio


def _make_adapter() -> UpdatePostAdapter:
    from app.bootstrap.container import container as _di_container

    return UpdatePostAdapter(session_factory=_di_container.session_factory())


# ── F8: get_post_by_id ────────────────────────────────────────────────────────


async def test_get_post_by_id_returns_post_item_for_active_post(
    up28_alice_post: dict,
) -> None:
    """F8 — active post row → PostItem with correct id."""
    adapter = _make_adapter()
    post = await adapter.get_post_by_id(up28_alice_post["id"])
    assert isinstance(post, PostItem)
    assert post.id == up28_alice_post["id"]
    assert post.title == "Original title"


async def test_get_post_by_id_returns_none_for_unknown(
    async_client: AsyncClient,
) -> None:
    """F8 — unknown id → None."""
    adapter = _make_adapter()
    result = await adapter.get_post_by_id(999999999)
    assert result is None


async def test_get_post_by_id_returns_none_for_soft_deleted(
    up28_alice: dict,
    async_client: AsyncClient,
) -> None:
    """F8 — soft-deleted post → None."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=up28_alice["id"],
            title="Deleted post",
            text="Some text.",
            status="approved",
            is_deleted=True,
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_id = post.id

    adapter = _make_adapter()
    result = await adapter.get_post_by_id(post_id)
    assert result is None


# ── F9: update ────────────────────────────────────────────────────────────────


async def test_update_sets_fields_and_updated_at(
    up28_alice_post: dict,
    async_client: AsyncClient,
) -> None:
    """F9 — update sets non-None fields and updated_at in the DB row."""
    from app.bootstrap.container import container as _di_container
    from app.features.posts.update_post.domain.commands import UpdatePostCommand

    adapter = _make_adapter()
    command = UpdatePostCommand(
        target_username="up28alice",
        requester_username="up28alice",
        post_id=up28_alice_post["id"],
        title="New title",
    )
    await adapter.update(command)

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT title, text, updated_at FROM "post" WHERE id = :id'),
            {"id": up28_alice_post["id"]},
        )
        row = result.first()

    assert row is not None
    assert row.title == "New title"
    assert row.text == "Original text."
    assert row.updated_at is not None
