# FEATURE: erase_post — adapter unit tests (real test Postgres).
#
# Covers: F8, F9.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

from app.features.posts.erase_post.data.adapter import ErasePostAdapter
from app.features.posts.erase_post.domain.entities import ErasePostRecord
from app.features.posts.erase_post.domain.ports.erase_post_port import ErasePostPort

pytestmark = pytest.mark.asyncio


def _make_adapter() -> ErasePostAdapter:
    from app.bootstrap.container import container as _di_container

    return ErasePostAdapter(session_factory=_di_container.session_factory())


# ── isinstance / class declaration ────────────────────────────────────────────


async def test_adapter_is_instance_of_port() -> None:
    """Adapter must explicitly inherit ErasePostPort (greppable binding)."""
    from unittest.mock import MagicMock

    adapter = ErasePostAdapter(session_factory=MagicMock())
    assert isinstance(adapter, ErasePostPort)


# ── F8: find_post ─────────────────────────────────────────────────────────────


async def test_find_post_returns_record_for_active_owned_post(
    ep29_alice: dict,
    ep29_alice_post: dict,
) -> None:
    """F8 — post exists, owned by user, not deleted → ErasePostRecord."""
    adapter = _make_adapter()
    result = await adapter.find_post(ep29_alice_post["id"], owner_id=ep29_alice["id"])
    assert isinstance(result, ErasePostRecord)
    assert result.id == ep29_alice_post["id"]


async def test_find_post_returns_none_for_unknown_post(
    ep29_alice: dict,
    async_client: AsyncClient,
) -> None:
    """F8 — post id not in DB → None."""
    adapter = _make_adapter()
    result = await adapter.find_post(999999999, owner_id=ep29_alice["id"])
    assert result is None


async def test_find_post_returns_none_when_post_belongs_to_different_user(
    ep29_alice: dict,
    ep29_alice_post: dict,
    ep29_bob: dict,
) -> None:
    """F8 — post exists but owned by alice, not bob → None."""
    adapter = _make_adapter()
    result = await adapter.find_post(ep29_alice_post["id"], owner_id=ep29_bob["id"])
    assert result is None


async def test_find_post_returns_none_for_soft_deleted_post(
    ep29_alice: dict,
    async_client: AsyncClient,
) -> None:
    """F8 — post is soft-deleted → None."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=ep29_alice["id"],
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
    result = await adapter.find_post(post_id, owner_id=ep29_alice["id"])
    assert result is None


# ── F9: soft_delete ───────────────────────────────────────────────────────────


async def test_soft_delete_sets_is_deleted_and_deleted_at(
    ep29_alice_post: dict,
    async_client: AsyncClient,
) -> None:
    """F9 — after soft_delete, is_deleted=True and deleted_at is not None."""
    from app.bootstrap.container import container as _di_container

    adapter = _make_adapter()
    await adapter.soft_delete(ep29_alice_post["id"])

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT is_deleted, deleted_at FROM "post" WHERE id = :id'),
            {"id": ep29_alice_post["id"]},
        )
        row = result.first()

    assert row is not None
    assert row.is_deleted is True
    assert row.deleted_at is not None
