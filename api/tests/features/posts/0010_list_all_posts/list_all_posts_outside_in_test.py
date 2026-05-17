# FEATURE: list_all_posts — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F5, F11, F12, F14, F16 (see requirements.md).
#
# Red-state trigger: the GET /api/v1/posts route does not exist yet.
# The endpoint returns 404, failing the 200 assertion in Scenario 1.
# After list_all_posts is implemented the test turns green.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts"


async def test_list_all_posts_happy_path(
    async_client: AsyncClient,
    seed_users_and_posts,
) -> None:
    """Scenario 1 — all posts from all users returned newest-first with correct usernames."""
    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200, response.text
    body = response.json()

    # Top-level shape (F2)
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}, (
        f"Unexpected top-level keys: {set(body.keys())}"
    )
    assert body["total_count"] == 3  # F9
    assert body["page"] == 1
    assert body["items_per_page"] == 10
    assert len(body["items"]) == 3  # F5

    # Per-item shape (F3)
    expected_fields = {
        "id",
        "title",
        "text",
        "media_url",
        "created_at",
        "created_by_user_id",
        "username",
    }
    for item in body["items"]:
        assert expected_fields.issubset(item.keys()), f"Item missing required fields. Got: {set(item.keys())}"

    # Newest-first ordering (F11)
    assert body["items"][0]["title"] == "Newest Post", f"Expected newest post first, got: {body['items'][0]['title']!r}"
    assert body["items"][1]["title"] == "Middle Post"
    assert body["items"][2]["title"] == "Oldest Post"

    # Username resolved via JOIN, not from a request parameter (F4)
    assert body["items"][0]["username"] == "oit10alice"
    assert body["items"][1]["username"] == "oit10bob"
    assert body["items"][2]["username"] == "oit10alice"

    # No auth header was sent — endpoint is public (F14)
    # (The fixture sends no Authorization header; a 200 proves public access.)


async def test_list_all_posts_invalid_page_returns_422(
    async_client: AsyncClient,
    seed_users_and_posts,
) -> None:
    """Scenario 2 — page=0 is below the minimum of 1, FastAPI returns 422."""
    response = await async_client.get(_ENDPOINT, params={"page": 0})

    assert response.status_code == 422, response.text
