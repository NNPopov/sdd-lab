# FEATURE: migrate_get_post_route_username_to_user_id — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F9, F10, F11, F13, F15, F16 (see requirements.md).
#
# Red-state trigger: the current route is GET /{username}/post/{id} where the
# path param is typed str. Calling GET /{author_id}/post/{post_id} binds
# username="<int-as-str>", the adapter filters User.username == "<int>", finds
# nothing, returns None, and the use-case raises NotFound → HTTP 404 — failing
# Scenario 1 and Scenario 2 (both expect 200). Scenario 3 calls
# GET /gp54alice/post/1; the current str-typed route accepts the string segment
# and returns 404 (no such post) instead of the expected 422.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/post/{post_id}"


async def test_get_approved_post_by_user_id(
    async_client: AsyncClient,
    seeded_author,
    seeded_approved_post,
) -> None:
    """Scenario 1 — unauthenticated request fetches an approved post by integer ID."""
    response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id, post_id=seeded_approved_post.id))

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["id"] == seeded_approved_post.id
    assert body["status"] == "approved"
    assert body["created_by_user_id"] == seeded_author.id
    # username resolved via the User JOIN, not echoed from the URL.
    assert body["username"] == "gp54alice", f"Expected username='gp54alice' from JOIN, got {body['username']!r}"
    for field in ("title", "text", "media_url", "created_at", "post_uuid"):
        assert field in body, f"{field} missing from response; keys: {sorted(body.keys())}"


async def test_author_reads_own_pending_post(
    async_client: AsyncClient,
    seeded_author,
    seeded_pending_post,
) -> None:
    """Scenario 2 — the authenticated author can read their own non-approved post."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: {
        "id": seeded_author.id,
        "username": "gp54alice",
        "is_superuser": False,
        "is_moderator": False,
    }
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id, post_id=seeded_pending_post.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["id"] == seeded_pending_post.id
    assert body["status"] == "pending"
    assert body["created_by_user_id"] == seeded_author.id
    assert body["username"] == "gp54alice"


async def test_old_username_route_returns_422(
    async_client: AsyncClient,
) -> None:
    """Scenario 3 — the old /{username}/post/{id} URL is gone; a string segment yields 422."""
    response = await async_client.get("/api/v1/gp54alice/post/1")

    assert response.status_code == 422, response.text
