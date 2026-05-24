# FEATURE: get_user_by_id — outside-in acceptance test.
#
# Covers: F1, F2, F4, F6, F10, F11 (see requirements.md).
# Red-state trigger: the new slice (GetUserByIdUseCase / GetUserByIdAdapter)
# does not yet exist.  GET /user/{user_id} either resolves to the old
# get_user_by_username handler (which does a username lookup, returning 404)
# or is unregistered (405/404).  Scenario 2 currently hits the old string-
# param handler and returns 404 instead of 422.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}"


async def test_get_user_by_id_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — create a user via POST /users then GET by integer id returns 200."""
    create_response = await async_client.post(
        "/api/v1/user",
        json={
            "username": "alice_oit",
            "name": "Alice OIT",
            "email": "alice_oit@example.com",
            "password": "Pa$$w0rd1",
        },
    )
    assert create_response.status_code == 201, create_response.text
    user_id = create_response.json()["id"]

    response = await async_client.get(_ENDPOINT.format(user_id=user_id))

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["id"] == user_id
    assert body["username"] == "alice_oit"
    assert body["name"] == "Alice OIT"
    assert body["email"] == "alice_oit@example.com"
    assert isinstance(body["profile_image_url"], str)
    assert body["tier_id"] is None
    assert body["is_moderator"] is False

    assert set(body.keys()) == {"id", "name", "username", "email", "profile_image_url", "tier_id", "is_moderator"}, (
        f"Unexpected response keys: {set(body.keys())}"
    )


async def test_get_user_by_id_non_integer_path_returns_422(async_client: AsyncClient) -> None:
    """Scenario 2 — string value in path (old username-URL shape) returns 422."""
    response = await async_client.get("/api/v1/user/alice_oit")

    assert response.status_code == 422, response.text
