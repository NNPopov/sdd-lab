# FEATURE: moderate_post — outside-in acceptance test.
#
# Covers: F1, F11, F14, F15, F17 (scenario 1 — happy path: approve)
#         F8 (scenario 2 — self-review guard → 403)
#
# Red-state trigger: POST /api/v1/posts/{post_uuid}/moderate route does not
# yet exist → requests return 404 and the status assertions fail.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_MODERATE_ENDPOINT = "/api/v1/posts/{post_uuid}/moderate"


async def test_moderate_post_happy_path(
    async_client: AsyncClient,
    seeded_post_author: dict,
    seeded_moderator: dict,
    seeded_pending_post: dict,
) -> None:
    """Scenario 1 — moderator approves a pending_review post owned by another user.

    Verifies HTTP 200, correct response body shape, Post.status updated to
    'approved', and a PostModerationLog row inserted with event_type='moderator_review'.
    """
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _MODERATE_ENDPOINT.format(post_uuid=seeded_pending_post["uuid"]),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert str(body["post_uuid"]) == str(seeded_pending_post["uuid"])
    assert body["status"] == "approved"
    assert body["log_entry"]["event_type"] == "moderator_review"
    assert body["log_entry"]["action"] == "approved"
    assert body["log_entry"]["message"] is None
    assert isinstance(body["log_entry"]["id"], int)
    assert "created_at" in body["log_entry"]

    # DB assertion: Post.status must be written to 'approved'.
    async with _di_container.session_factory()() as session:
        post_result = await session.execute(
            text('SELECT status FROM "post" WHERE id = :id'),
            {"id": seeded_pending_post["id"]},
        )
        post_row = post_result.first()
        assert post_row is not None, "post row not found after moderation"
        assert post_row.status == "approved"

    # DB assertion: PostModerationLog row must exist with correct fields.
    async with _di_container.session_factory()() as session:
        log_result = await session.execute(
            text('SELECT event_type, action, message, user_id FROM "post_moderation_log" WHERE post_id = :post_id'),
            {"post_id": seeded_pending_post["id"]},
        )
        log_row = log_result.first()
        assert log_row is not None, "moderation log row not found after approve"
        assert log_row.event_type == "moderator_review"
        assert log_row.action == "approved"
        assert log_row.message is None
        assert log_row.user_id == seeded_moderator["id"]


async def test_moderate_post_self_review_forbidden(
    async_client: AsyncClient,
    seeded_moderator: dict,
) -> None:
    """Scenario 2 — moderator attempts to approve their own post; must receive 403.

    Verifies that the self-review guard (F8) rejects the request, Post.status
    remains 'pending_review', and no PostModerationLog row is created.
    """
    from sqlalchemy import text

    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    # Seed a post owned by the moderator (same user who will call the endpoint).
    async with _di_container.session_factory()() as session:
        own_post = Post(
            created_by_user_id=seeded_moderator["id"],
            title="Own Post",
            text="The moderator's own post — self-review is forbidden.",
        )
        session.add(own_post)
        await session.commit()
        await session.refresh(own_post)
        own_post_id = own_post.id
        own_post_uuid = own_post.uuid

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_moderator
    try:
        response = await async_client.post(
            _MODERATE_ENDPOINT.format(post_uuid=own_post_uuid),
            json={"action": "approved"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json()["error"]["message"] == "Moderators may not review their own posts"

    # DB assertion: Post.status must remain 'pending_review'.
    async with _di_container.session_factory()() as session:
        post_result = await session.execute(
            text('SELECT status FROM "post" WHERE id = :id'),
            {"id": own_post_id},
        )
        post_row = post_result.first()
        assert post_row is not None
        assert post_row.status == "pending_review"

    # DB assertion: no PostModerationLog row must have been created.
    async with _di_container.session_factory()() as session:
        log_result = await session.execute(
            text('SELECT id FROM "post_moderation_log" WHERE post_id = :post_id'),
            {"post_id": own_post_id},
        )
        log_row = log_result.first()
        assert log_row is None, "no moderation log row should exist after self-review rejection"
