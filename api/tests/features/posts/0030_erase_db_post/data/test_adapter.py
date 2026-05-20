# FEATURE: erase_db_post — adapter unit tests (real test Postgres).
#
# Covers: F5, F6, F7.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

from app.features.posts._shared.entities import PostAuthor
from app.features.posts.erase_db_post.data.adapter import EraseDbPostAdapter
from app.features.posts.erase_db_post.domain.entities import EraseDbPostRecord
from app.features.posts.erase_db_post.domain.ports.erase_db_post_port import EraseDbPostPort

pytestmark = pytest.mark.asyncio


def _make_adapter() -> EraseDbPostAdapter:
    from app.bootstrap.container import container as _di_container

    return EraseDbPostAdapter(session_factory=_di_container.session_factory())


# ── isinstance / class declaration ────────────────────────────────────────────


async def test_adapter_is_instance_of_port() -> None:
    """Adapter must explicitly inherit EraseDbPostPort (greppable binding)."""
    from unittest.mock import MagicMock

    adapter = EraseDbPostAdapter(session_factory=MagicMock())
    assert isinstance(adapter, EraseDbPostPort)


# ── F5: get_user_by_username ──────────────────────────────────────────────────


async def test_get_user_by_username_returns_post_author_for_active_user(
    ep30_alice: dict,
) -> None:
    """F5 — active user row → PostAuthor with correct id and username."""
    adapter = _make_adapter()
    author = await adapter.get_user_by_username("ep30alice")
    assert isinstance(author, PostAuthor)
    assert author.username == "ep30alice"
    assert author.id == ep30_alice["id"]


async def test_get_user_by_username_returns_none_for_unknown(
    async_client: AsyncClient,
) -> None:
    """F5 — unknown username → None."""
    adapter = _make_adapter()
    result = await adapter.get_user_by_username("no_such_user_ep30")
    assert result is None


async def test_get_user_by_username_returns_none_for_soft_deleted(
    async_client: AsyncClient,
) -> None:
    """F5 — soft-deleted user → None."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EP30 Deleted",
            username="ep30deleted_xyz",
            email="ep30deleted_xyz@example.com",
            hashed_password="fake",
            is_deleted=True,
        )
        session.add(user)
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get_user_by_username("ep30deleted_xyz")
    assert result is None


# ── F6: find_post ─────────────────────────────────────────────────────────────


async def test_find_post_returns_record_for_active_owned_post(
    ep30_alice: dict,
    ep30_alice_post: dict,
) -> None:
    """F6 — post exists, owned by user, not deleted → EraseDbPostRecord."""
    adapter = _make_adapter()
    result = await adapter.find_post(ep30_alice_post["id"], owner_id=ep30_alice["id"])
    assert isinstance(result, EraseDbPostRecord)
    assert result.id == ep30_alice_post["id"]


async def test_find_post_returns_none_for_unknown_post(
    ep30_alice: dict,
    async_client: AsyncClient,
) -> None:
    """F6 — post id not in DB → None."""
    adapter = _make_adapter()
    result = await adapter.find_post(999999999, owner_id=ep30_alice["id"])
    assert result is None


async def test_find_post_returns_none_when_post_belongs_to_different_user(
    ep30_alice: dict,
    ep30_alice_post: dict,
    ep30_bob: dict,
) -> None:
    """F6 — post exists but owned by alice, not bob → None."""
    adapter = _make_adapter()
    result = await adapter.find_post(ep30_alice_post["id"], owner_id=ep30_bob["id"])
    assert result is None


async def test_find_post_returns_none_for_soft_deleted_post(
    ep30_alice: dict,
    async_client: AsyncClient,
) -> None:
    """F6 — post is soft-deleted → None."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=ep30_alice["id"],
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
    result = await adapter.find_post(post_id, owner_id=ep30_alice["id"])
    assert result is None


# ── F7: hard_delete ───────────────────────────────────────────────────────────


async def test_hard_delete_removes_row_permanently(
    ep30_alice_post: dict,
    async_client: AsyncClient,
) -> None:
    """F7 — after hard_delete the row does not exist in the DB (permanently gone)."""
    from app.bootstrap.container import container as _di_container

    adapter = _make_adapter()
    await adapter.hard_delete(ep30_alice_post["id"])

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "post" WHERE id = :id'),
            {"id": ep30_alice_post["id"]},
        )
        row = result.first()

    assert row is None, "post row still exists after hard_delete"


async def test_hard_delete_removes_post_and_moderation_logs(
    ep30_alice: dict,
    ep30_alice_post: dict,
    async_client: AsyncClient,
) -> None:
    """F2 — hard_delete removes the post row and all PostModerationLog rows in the same transaction."""
    from app.bootstrap.container import container as _di_container

    post_id = ep30_alice_post["id"]

    async with _di_container.session_factory()() as session:
        log_insert = await session.execute(
            text(
                "INSERT INTO post_moderation_log"
                " (post_id, user_id, event_type, action, message, created_at)"
                " VALUES (:post_id, :user_id, :event_type, :action, :message, NOW()) RETURNING id"
            ),
            {
                "post_id": post_id,
                "user_id": ep30_alice["id"],
                "event_type": "moderate",
                "action": "approve",
                "message": "seeded for cascade test",
            },
        )
        await session.commit()
        log_id = log_insert.scalar_one()

    adapter = _make_adapter()
    await adapter.hard_delete(post_id)

    async with _di_container.session_factory()() as session:
        post_result = await session.execute(
            text('SELECT id FROM "post" WHERE id = :id'),
            {"id": post_id},
        )
        assert post_result.first() is None, "post row still exists after hard_delete"

        log_result = await session.execute(
            text("SELECT id FROM post_moderation_log WHERE post_id = :post_id"),
            {"post_id": post_id},
        )
        assert log_result.first() is None, f"post_moderation_log row {log_id} still exists after hard_delete"
