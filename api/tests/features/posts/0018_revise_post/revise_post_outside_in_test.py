# FEATURE: revise_post — outside-in acceptance test.
#
# Covers: F1, F7, F8, F9, F10, F11, F12, F13, F14, F15 (scenario 1 — happy path)
#         F6 (scenario 2 — wrong-status guard → 403)
#
# Red-state trigger: PATCH /api/v1/posts/{post_uuid}/revise route does not
# yet exist → requests return 404 or 405 and the status assertions fail.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_REVISE_ENDPOINT = "/api/v1/posts/{post_uuid}/revise"


async def test_revise_post_happy_path(
    async_client: AsyncClient,
    seeded_revise_author: dict,
    seeded_changes_requested_post: dict,
) -> None:
    """Scenario 1 — author revises a changes_requested post; status returns to pending_review.

    Verifies HTTP 200, correct response body shape, Post.title updated, Post.text
    unchanged, Post.status set to 'pending_review', and a PostModerationLog row
    inserted with event_type='author_revision' and action=NULL.
    """
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _REVISE_ENDPOINT.format(post_uuid=seeded_changes_requested_post["uuid"]),
            json={"title": "Revised Title", "message": "Fixed the title as requested."},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert str(body["post_uuid"]) == str(seeded_changes_requested_post["uuid"])
    assert body["title"] == "Revised Title"
    assert body["text"] == seeded_changes_requested_post["text"]  # unchanged
    assert body["status"] == "pending_review"
    assert "updated_at" in body
    assert body["log_entry"]["event_type"] == "author_revision"
    assert body["log_entry"]["action"] is None
    assert body["log_entry"]["message"] == "Fixed the title as requested."
    assert isinstance(body["log_entry"]["id"], int)
    assert "created_at" in body["log_entry"]

    # DB assertion: Post row must reflect the revision.
    async with _di_container.session_factory()() as session:
        post_result = await session.execute(
            text('SELECT status, title, text FROM "post" WHERE id = :id'),
            {"id": seeded_changes_requested_post["id"]},
        )
        post_row = post_result.first()
        assert post_row is not None, "post row not found after revision"
        assert post_row.status == "pending_review"
        assert post_row.title == "Revised Title"
        assert post_row.text == seeded_changes_requested_post["text"]  # unchanged

    # DB assertion: PostModerationLog row must exist with correct fields.
    async with _di_container.session_factory()() as session:
        log_result = await session.execute(
            text('SELECT event_type, action, message, user_id FROM "post_moderation_log" WHERE post_id = :post_id'),
            {"post_id": seeded_changes_requested_post["id"]},
        )
        log_row = log_result.first()
        assert log_row is not None, "moderation log row not found after revision"
        assert log_row.event_type == "author_revision"
        assert log_row.action is None
        assert log_row.message == "Fixed the title as requested."
        assert log_row.user_id == seeded_revise_author["id"]


async def test_revise_post_wrong_status_forbidden(
    async_client: AsyncClient,
    seeded_revise_author: dict,
    seeded_pending_review_post: dict,
) -> None:
    """Scenario 2 — author attempts to revise a post that is still in pending_review; must receive 403.

    Verifies that the status guard (F6) rejects the request, Post.status
    remains 'pending_review', and no PostModerationLog row is created.
    """
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_revise_author
    try:
        response = await async_client.patch(
            _REVISE_ENDPOINT.format(post_uuid=seeded_pending_review_post["uuid"]),
            json={"title": "Attempted revision"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json()["error"]["message"] == "Post is not in changes_requested status"

    # DB assertion: Post.status must remain 'pending_review'.
    async with _di_container.session_factory()() as session:
        post_result = await session.execute(
            text('SELECT status, title FROM "post" WHERE id = :id'),
            {"id": seeded_pending_review_post["id"]},
        )
        post_row = post_result.first()
        assert post_row is not None
        assert post_row.status == "pending_review"
        assert post_row.title == "Fresh Post"  # unchanged

    # DB assertion: no PostModerationLog row must have been created.
    async with _di_container.session_factory()() as session:
        log_result = await session.execute(
            text('SELECT id FROM "post_moderation_log" WHERE post_id = :post_id'),
            {"post_id": seeded_pending_review_post["id"]},
        )
        log_row = log_result.first()
        assert log_row is None, "no moderation log row should exist after status-guard rejection"
