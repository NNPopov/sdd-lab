# FEATURE: get_moderation_log — outside-in acceptance test.
#
# Covers: F1, F6, F11, F12, F13 (scenario 1 — happy path: author reads ordered log)
#         F5                     (scenario 2 — plain user receives 403)
#
# Red-state trigger: GET /api/v1/posts/{post_uuid}/moderation-log route does not yet
# exist → requests return 404 and the status assertions fail.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts/{post_uuid}/moderation-log"


async def test_get_moderation_log_happy_path(
    async_client: AsyncClient,
    seeded_gml_author: dict,
    seeded_gml_moderator: dict,
    seeded_gml_post_with_log: dict,
) -> None:
    """Scenario 1 — author reads a log with two chronologically ordered entries.

    Verifies HTTP 200, correct GetModerationLogResponse shape, both log entries
    present, actor_username resolved via JOIN (not stored in the log row), and
    entries ordered oldest-first by created_at.
    """
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_author
    try:
        response = await async_client.get(_ENDPOINT.format(post_uuid=str(seeded_gml_post_with_log["uuid"])))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert "items" in body, f"response missing 'items' key: {body}"
    assert len(body["items"]) == 2, f"expected 2 log entries, got {len(body['items'])}: {body['items']}"

    entry0 = body["items"][0]
    assert entry0["event_type"] == "moderator_review"
    assert entry0["action"] == "changes_requested"
    assert entry0["message"] == "Please fix the intro."
    assert entry0["actor_username"] == "gmlmod"
    assert entry0["actor_user_id"] == seeded_gml_moderator["id"]
    assert "id" in entry0
    assert "created_at" in entry0

    entry1 = body["items"][1]
    assert entry1["event_type"] == "author_revision"
    assert entry1["action"] is None
    assert entry1["message"] == "Fixed the intro."
    assert entry1["actor_username"] == "gmlauthor"
    assert entry1["actor_user_id"] == seeded_gml_author["id"]
    assert "id" in entry1
    assert "created_at" in entry1

    assert entry0["created_at"] < entry1["created_at"], (
        f"log entries not in chronological order: {entry0['created_at']} >= {entry1['created_at']}"
    )


async def test_get_moderation_log_forbidden_for_plain_user(
    async_client: AsyncClient,
    seeded_gml_plain_user: dict,
    seeded_gml_post_with_log: dict,
) -> None:
    """Scenario 2 — plain user (not author/moderator/superuser) receives HTTP 403.

    Verifies that the use-case raises ForbiddenDomainError when none of the
    three authorization conditions hold, and the exception handler maps it to 403.
    """
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_gml_plain_user
    try:
        response = await async_client.get(_ENDPOINT.format(post_uuid=str(seeded_gml_post_with_log["uuid"])))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    body = response.json()
    assert "message" in body["error"], f"403 response missing 'error.message' key: {body}"
