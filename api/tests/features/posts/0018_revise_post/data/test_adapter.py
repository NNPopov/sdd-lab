# FEATURE: revise_post — adapter unit tests (real test Postgres).
#
# Covers: F8, F9, F10, F11, F12, F13, F14.
import uuid

import pytest
from httpx import AsyncClient

from app.features.posts.revise_post.data.adapter import RevisePostAdapter
from app.features.posts.revise_post.domain.entities import PostForRevision, RevisedPostResult

pytestmark = pytest.mark.asyncio


def _make_adapter() -> RevisePostAdapter:
    from app.bootstrap.container import container as _di_container

    return RevisePostAdapter(session_factory=_di_container.session_factory())


# ── F13: get_post_by_uuid — not found ────────────────────────────────────────


async def test_get_post_by_uuid_returns_none_for_unknown(
    async_client: AsyncClient,
) -> None:
    """F13 — UUID not in DB → None returned."""
    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(uuid.uuid4())
    assert result is None


# ── F14: get_post_by_uuid — found ────────────────────────────────────────────


async def test_get_post_by_uuid_returns_post_for_revision(
    seeded_changes_requested_post: dict,
    seeded_revise_author: dict,
) -> None:
    """F14 — existing post UUID → PostForRevision with correct fields."""
    adapter = _make_adapter()
    result = await adapter.get_post_by_uuid(seeded_changes_requested_post["uuid"])
    assert isinstance(result, PostForRevision)
    assert result.id == seeded_changes_requested_post["id"]
    assert result.uuid == seeded_changes_requested_post["uuid"]
    assert result.status == "changes_requested"
    assert result.created_by_user_id == seeded_revise_author["id"]


# ── F9, F12: apply_revision — title-only update ───────────────────────────────


async def test_apply_revision_title_only(
    seeded_changes_requested_post: dict,
    seeded_revise_author: dict,
) -> None:
    """F9, F12 — title updated, text unchanged; result reflects post state after UPDATE."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    adapter = _make_adapter()
    result = await adapter.apply_revision(
        post_id=seeded_changes_requested_post["id"],
        post_uuid=seeded_changes_requested_post["uuid"],
        title="Brand New Title",
        text=None,
        author_user_id=seeded_revise_author["id"],
        message=None,
    )

    assert isinstance(result, RevisedPostResult)
    assert result.title == "Brand New Title"
    assert result.text == seeded_changes_requested_post["text"]  # unchanged
    assert result.status == "pending_review"

    async with _di_container.session_factory()() as session:
        row = (
            await session.execute(
                text('SELECT title, text, status FROM "post" WHERE id = :id'),
                {"id": seeded_changes_requested_post["id"]},
            )
        ).first()
    assert row is not None
    assert row.title == "Brand New Title"
    assert row.text == seeded_changes_requested_post["text"]
    assert row.status == "pending_review"


# ── F10, F12: apply_revision — text-only update ───────────────────────────────


async def test_apply_revision_text_only(
    seeded_changes_requested_post: dict,
    seeded_revise_author: dict,
) -> None:
    """F10, F12 — text updated, title unchanged; result reflects post state after UPDATE."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    adapter = _make_adapter()
    result = await adapter.apply_revision(
        post_id=seeded_changes_requested_post["id"],
        post_uuid=seeded_changes_requested_post["uuid"],
        title=None,
        text="Completely rewritten body.",
        author_user_id=seeded_revise_author["id"],
        message=None,
    )

    assert result.title == seeded_changes_requested_post["title"]  # unchanged
    assert result.text == "Completely rewritten body."
    assert result.status == "pending_review"

    async with _di_container.session_factory()() as session:
        row = (
            await session.execute(
                text('SELECT title, text FROM "post" WHERE id = :id'),
                {"id": seeded_changes_requested_post["id"]},
            )
        ).first()
    assert row is not None
    assert row.title == seeded_changes_requested_post["title"]
    assert row.text == "Completely rewritten body."


# ── F8, F9, F10: apply_revision — both fields updated ─────────────────────────


async def test_apply_revision_both_fields(
    seeded_revise_author: dict,
    async_client: AsyncClient,
) -> None:
    """F8, F9, F10 — both title and text updated; status set to 'pending_review'."""
    from sqlalchemy import text

    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=seeded_revise_author["id"],
            title="Old Title",
            text="Old body.",
            status="changes_requested",
        )
        session.add(post)
        await session.commit()
        await session.refresh(post)
        post_id, post_uuid = post.id, post.uuid

    adapter = _make_adapter()
    result = await adapter.apply_revision(
        post_id=post_id,
        post_uuid=post_uuid,
        title="New Title",
        text="New body.",
        author_user_id=seeded_revise_author["id"],
        message=None,
    )

    assert result.title == "New Title"
    assert result.text == "New body."
    assert result.status == "pending_review"

    async with _di_container.session_factory()() as session:
        row = (
            await session.execute(
                text('SELECT title, text, status FROM "post" WHERE id = :id'),
                {"id": post_id},
            )
        ).first()
    assert row is not None
    assert row.title == "New Title"
    assert row.text == "New body."
    assert row.status == "pending_review"


# ── F11: apply_revision — log row created ────────────────────────────────────


async def test_apply_revision_log_row_created(
    seeded_changes_requested_post: dict,
    seeded_revise_author: dict,
) -> None:
    """F11 — PostModerationLog row inserted with event_type='author_revision', action=None."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    adapter = _make_adapter()
    result = await adapter.apply_revision(
        post_id=seeded_changes_requested_post["id"],
        post_uuid=seeded_changes_requested_post["uuid"],
        title="Title with message",
        text=None,
        author_user_id=seeded_revise_author["id"],
        message="Here is my revision note.",
    )

    assert result.log_entry.event_type == "author_revision"
    assert result.log_entry.action is None
    assert result.log_entry.message == "Here is my revision note."
    assert isinstance(result.log_entry.id, int)

    async with _di_container.session_factory()() as session:
        log_row = (
            await session.execute(
                text('SELECT event_type, action, message, user_id FROM "post_moderation_log" WHERE post_id = :post_id'),
                {"post_id": seeded_changes_requested_post["id"]},
            )
        ).first()
    assert log_row is not None
    assert log_row.event_type == "author_revision"
    assert log_row.action is None
    assert log_row.message == "Here is my revision note."
    assert log_row.user_id == seeded_revise_author["id"]
