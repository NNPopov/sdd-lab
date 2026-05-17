# FEATURE: get_user_by_username — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F5, F6, F8, F9, F10 (see requirements.md).
# Red-state trigger: the new slice (GetUserByUsernameUseCase / GetUserByUsernameAdapter)
# does not yet exist.  The container cannot resolve get_user_by_username_use_case,
# so the endpoint raises an AttributeError / ImportError before serving the request.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{username}"


async def test_get_user_by_username_happy_path(
    async_client: AsyncClient,
    seeded_user,
) -> None:
    """Scenario 1 — existing active user returns 200 with all six contracted fields."""
    response = await async_client.get(_ENDPOINT.format(username="alicetester"))

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
    """Scenario 2 — username with no matching row returns 404."""
    response = await async_client.get(_ENDPOINT.format(username="ghost"))

    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}
