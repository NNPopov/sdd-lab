# FEATURE: moderate_post — adapter unit tests (real test Postgres).
#
# Covers: F12, F13, F14, F15, F16, F17.
import uuid

import pytest
from httpx import AsyncClient

from app.features.posts.moderate_post.data.adapter import ModeratePostAdapter
from app.features.posts.moderate_post.domain.entities import ModeratedPostResult, PostForModeration

pytestmark = pytest.mark.asyncio


def _make_adapter() -> ModeratePostAdapter:
    from app.bootstrap.container import container as _di_container

    return ModeratePostAdapter(session_factory=_di_container.session_factory())


# ── F12: get_post_by_uuid — not found ────────────────────────────────────────


async def test_get_post_by_uuid_returns_none_for_unknown(
    async_client: AsyncClient,
) -> None:
    """F12 — UUID not in DB → None returned."""
    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(uuid.uuid4())
    assert result is None


# ── F13: get_post_by_uuid — found ────────────────────────────────────────────


async def test_get_post_by_uuid_returns_post_for_moderation(
    seeded_pending_post: dict,
    seeded_post_author: dict,
) -> None:
    """F13 — existing post UUID → PostForModeration with correct fields."""
    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(seeded_pending_post["uuid"])
    assert isinstance(result, PostForModeration)
    assert result.id == seeded_pending_post["id"]
    assert result.uuid == seeded_pending_post["uuid"]
    assert result.status == "pending_review"
    assert result.created_by_user_id == seeded_post_author["id"]


# ── F14, F15, F17: apply_decision — approve ──────────────────────────────────


async def test_apply_decision_approve_updates_post_and_inserts_log(
    seeded_pending_post: dict,
    seeded_moderator: dict,
) -> None:
    """F14, F15, F17 — approve action: post status updated, log row inserted."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    adapter = _make_adapter()
    result = await adapter.apply_decision(
        post_id=seeded_pending_post["id"],
        post_uuid=seeded_pending_post["uuid"],
        action="approved",
        moderator_user_id=seeded_moderator["id"],
        message=None,
    )

    assert isinstance(result, ModeratedPostResult)
    assert result.status == "approved"
    assert result.post_uuid == seeded_pending_post["uuid"]
    assert result.log_entry.event_type == "moderator_review"
    assert result.log_entry.action == "approved"
    assert result.log_entry.message is None
    assert isinstance(result.log_entry.id, int)

    # Verify DB state: post status updated.
    async with _di_container.session_factory()() as session:
        post_row = (
            await session.execute(
                text('SELECT status FROM "post" WHERE id = :id'),
                {"id": seeded_pending_post["id"]},
            )
        ).first()
    assert post_row is not None
    assert post_row.status == "approved"

    # Verify DB state: log row inserted (F16 — no UPDATE or DELETE).
    async with _di_container.session_factory()() as session:
        log_row = (
            await session.execute(
                text('SELECT event_type, action, message, user_id FROM "post_moderation_log" WHERE post_id = :post_id'),
                {"post_id": seeded_pending_post["id"]},
            )
        ).first()
    assert log_row is not None
    assert log_row.event_type == "moderator_review"
    assert log_row.action == "approved"
    assert log_row.message is None
    assert log_row.user_id == seeded_moderator["id"]


# ── F14, F15: apply_decision — changes_requested ─────────────────────────────


async def test_apply_decision_changes_requested_stores_message(
    seeded_post_author: dict,
    seeded_moderator: dict,
    async_client: AsyncClient,
) -> None:
    """F14, F15 — changes_requested: message stored in log row."""
    from sqlalchemy import text

    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_post_author["id"],
            title="Post for CR",
            text="Needs some changes.",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_id = post.id
        post_uuid = post.uuid

    adapter = _make_adapter()
    result = await adapter.apply_decision(
        post_id=post_id,
        post_uuid=post_uuid,
        action="changes_requested",
        moderator_user_id=seeded_moderator["id"],
        message="Please revise the introduction.",
    )

    assert result.status == "changes_requested"
    assert result.log_entry.action == "changes_requested"
    assert result.log_entry.message == "Please revise the introduction."

    async with _di_container.session_factory()() as session:
        log_row = (
            await session.execute(
                text('SELECT action, message FROM "post_moderation_log" WHERE post_id = :post_id'),
                {"post_id": post_id},
            )
        ).first()
    assert log_row is not None
    assert log_row.action == "changes_requested"
    assert log_row.message == "Please revise the introduction."
