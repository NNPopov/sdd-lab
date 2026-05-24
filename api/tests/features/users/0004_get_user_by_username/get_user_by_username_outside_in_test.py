# FEATURE: get_user_by_username — outside-in acceptance test.
#
# Updated after slice 0041 (get_user_by_id) retired the username-based route.
# The GET /user/{username} endpoint was replaced by GET /user/{user_id}.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}"


async def test_get_user_by_username_happy_path(
    async_client: AsyncClient,
    seeded_user,
) -> None:
    """Existing active user returns 200 with all seven contracted fields."""
    response = await async_client.get(_ENDPOINT.format(user_id=seeded_user.id))

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["username"] == "alicetester"
    assert body["name"] == "Alice Tester"
    assert body["email"] == "alice@example.com"
    assert body["profile_image_url"] == "https://www.profileimageurl.com"
    assert body["tier_id"] is None
    assert isinstance(body["id"], int) and body["id"] > 0

    # Contracted fields — no internal fields leaked.
    assert set(body.keys()) == {"id", "name", "username", "email", "profile_image_url", "tier_id", "is_moderator"}, (
        f"Unexpected response keys: {set(body.keys())}"
    )


async def test_get_user_by_username_not_found(
    async_client: AsyncClient,
) -> None:
    """Non-existent integer id returns 404."""
    response = await async_client.get(_ENDPOINT.format(user_id=999_999))

    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}
