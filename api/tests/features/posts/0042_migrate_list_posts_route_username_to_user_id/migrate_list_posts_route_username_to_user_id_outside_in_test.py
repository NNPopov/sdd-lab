# FEATURE: migrate_list_posts_route_username_to_user_id — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F8, F9, F10, F11, F15, F16, F18 (see requirements.md).
#
# Red-state trigger: the current route is GET /{username}/posts where the path
# param is typed str. Calling GET /{author_id}/posts binds username="<int-as-str>",
# the adapter filters User.username == "<int>", finds nothing, and returns 200 with
# an empty page (total_count == 0) — failing Scenario 1 (expects 1) and Scenario 2
# (expects 2). Scenario 3 calls GET /alicepost/posts; the current str-typed route
# accepts the string and returns 200 instead of the expected 422.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/posts"


async def test_list_posts_public_view_by_user_id(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    """Scenario 1 — unauthenticated request lists only approved posts by integer ID."""
    response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))

    assert response.status_code == 200, response.text
    body = response.json()

    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}, (
        f"Unexpected top-level keys: {set(body.keys())}"
    )
    assert body["total_count"] == 1
    assert body["page"] == 1
    assert body["items_per_page"] == 10
    assert len(body["items"]) == 1

    item = body["items"][0]
    assert item["status"] == "approved"
    assert item["created_by_user_id"] == seeded_author.id
    # username resolved via the User JOIN, not echoed from the URL.
    assert item["username"] == "alicepost", f"Expected username='alicepost' from JOIN, got {item['username']!r}"


async def test_list_posts_author_view_includes_pending(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    """Scenario 2 — the authenticated owner sees the non-approved post too."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: {
        "id": seeded_author.id,
        "username": "alicepost",
    }
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 2
    assert len(body["items"]) == 2
    assert {item["status"] for item in body["items"]} == {"approved", "pending"}
    for item in body["items"]:
        assert item["created_by_user_id"] == seeded_author.id
        assert item["username"] == "alicepost"


async def test_old_username_route_returns_422(
    async_client: AsyncClient,
) -> None:
    """Scenario 3 — the old /{username}/posts URL is gone; a string segment yields 422."""
    response = await async_client.get("/api/v1/alicepost/posts")

    assert response.status_code == 422, response.text
