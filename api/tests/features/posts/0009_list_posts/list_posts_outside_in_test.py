# FEATURE: list_posts — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F5, F9, F10, F15 (see requirements.md).
#
# Red-state trigger: the current read_posts handler injects its DB session via
# async_get_db (not the DI container's overridden session_factory), so the
# user and posts seeded through the test fixture are invisible to it.
# The handler raises NotFoundDomainError -> HTTP 404, failing the 200 assertion.
# After the new list_posts slice is implemented (adapter uses the DI container's
# session_factory), the test turns green.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/posts"


async def test_list_posts_happy_path(
    async_client: AsyncClient,
    seeded_user,
    seeded_posts,
) -> None:
    """Scenario 1 — user with two posts returns 200 with items including username from JOIN."""
    response = await async_client.get(_ENDPOINT.format(username="alicepost"))

    assert response.status_code == 200, response.text
    body = response.json()

    # Shape assertion — primary RED trigger
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}, (
        f"Unexpected top-level keys: {set(body.keys())}"
    )

    assert body["total_count"] == 2
    assert body["page"] == 1
    assert body["items_per_page"] == 10
    assert len(body["items"]) == 2

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
        # username resolved via JOIN, not echoed from the URL
        assert item["username"] == "alicepost", f"Expected username='alicepost' from JOIN, got {item['username']!r}"
        assert item["created_by_user_id"] == seeded_user.id


async def test_list_posts_unknown_username_returns_empty(
    async_client: AsyncClient,
) -> None:
    """Scenario 2 — non-existent username returns 200 with an empty paginated response."""
    response = await async_client.get(_ENDPOINT.format(username="ghost"))

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["items"] == []
    assert body["total_count"] == 0
    assert body["page"] == 1
    assert body["items_per_page"] == 10
