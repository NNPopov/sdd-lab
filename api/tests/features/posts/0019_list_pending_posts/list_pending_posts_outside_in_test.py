# FEATURE: list_pending_posts — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F5, F9, F10, F17 (scenario 1 — happy path: moderator retrieves queue)
#         F14, F16 (scenario 2 — regular user receives 403)
#
# Red-state trigger: GET /api/v1/posts/pending route does not yet exist →
# requests return 404 and the status assertions fail.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_LIST_PENDING_ENDPOINT = "/api/v1/posts/pending"


async def test_list_pending_posts_happy_path(
    async_client: AsyncClient,
    seeded_lpp_author: dict,
    seeded_lpp_moderator: dict,
    seeded_lpp_post_with_log_entries: dict,
) -> None:
    """Scenario 1 — moderator retrieves the pending queue; post has two ordered log entries.

    Verifies HTTP 200, correct ListPendingPostsResponse shape, post status
    'pending_review', author_username resolved via JOIN, and moderation_log
    ordered chronologically (oldest-first) with both entries present.
    """
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_moderator
    try:
        response = await async_client.get(_LIST_PENDING_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 1
    assert body["page"] == 1
    assert body["items_per_page"] == 10
    assert len(body["items"]) == 1

    item = body["items"][0]

    assert str(item["post_uuid"]) == str(seeded_lpp_post_with_log_entries["uuid"])
    assert item["status"] == "pending_review"
    assert item["title"] == "Review This Post"
    assert item["text"] == "Content waiting for moderation."
    assert item["media_url"] is None
    assert item["author_username"] == seeded_lpp_author["username"]
    assert "created_at" in item

    log = item["moderation_log"]
    assert len(log) == 2, f"expected 2 log entries, got {len(log)}: {log}"

    # Entry 0 — moderator requested changes.
    assert log[0]["event_type"] == "moderator_review"
    assert log[0]["action"] == "changes_requested"
    assert log[0]["message"] == "Please clarify section 2."
    assert isinstance(log[0]["id"], int)
    assert "created_at" in log[0]

    # Entry 1 — author revised.
    assert log[1]["event_type"] == "author_revision"
    assert log[1]["action"] is None
    assert log[1]["message"] == "Clarified section 2."
    assert isinstance(log[1]["id"], int)
    assert "created_at" in log[1]

    # Chronological order: entry 0 must be older than entry 1.
    assert log[0]["created_at"] < log[1]["created_at"], (
        f"log entries not in chronological order: {log[0]['created_at']} >= {log[1]['created_at']}"
    )


async def test_list_pending_posts_forbidden_for_regular_user(
    async_client: AsyncClient,
    seeded_lpp_plain_user: dict,
) -> None:
    """Scenario 2 — a plain (non-moderator) user receives HTTP 403.

    Verifies that get_current_moderator_or_superuser rejects the request before
    the use-case is reached, and the response has status 403.
    """
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_lpp_plain_user
    try:
        response = await async_client.get(_LIST_PENDING_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
