# FEATURE: create_user — outside-in acceptance test.
#
# Covers: F1, F4, F5, F7, F9, F12, F13, F15 (see requirements.md).
# Red-state trigger: ModuleNotFoundError for app.bootstrap.container,
# which does not exist until the slice is implemented.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user"

_VALID_PAYLOAD: dict[str, str] = {
    "name": "Alice Example",
    "username": "alice99",
    "email": "alice99@example.com",
    "password": "Str0ng!pw",
}


async def test_create_user_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — valid new user returns 201 with CreateUserResponse shape."""
    response = await async_client.post(_ENDPOINT, json=_VALID_PAYLOAD)

    assert response.status_code == 201, response.text

    body = response.json()
    assert isinstance(body["id"], int)
    assert body["name"] == "Alice Example"
    assert body["username"] == "alice99"
    assert body["email"] == "alice99@example.com"
    assert isinstance(body["profile_image_url"], str)
    assert body["tier_id"] is None

    # Confirm persistence: a second identical POST must return 409,
    # which proves the row was committed (not just returned in-memory).
    confirm_response = await async_client.post(_ENDPOINT, json=_VALID_PAYLOAD)
    assert confirm_response.status_code == 409, (
        "Expected 409 on duplicate after creation — row was not actually persisted."
    )


async def test_create_user_duplicate_email(async_client: AsyncClient) -> None:
    """Scenario 2 — duplicate email returns 409 with exact error payload."""
    # Seed: create alice99 so that her email exists in the database.
    seed_response = await async_client.post(_ENDPOINT, json=_VALID_PAYLOAD)
    assert seed_response.status_code == 201, f"Seed step failed unexpectedly: {seed_response.text}"

    # Act: different username, same email.
    duplicate_response = await async_client.post(
        _ENDPOINT,
        json={**_VALID_PAYLOAD, "username": "alice_clone"},
    )

    assert duplicate_response.status_code == 409, duplicate_response.text
    assert duplicate_response.json() == {
        "error": {
            "code": "duplicatevalue",
            "message": "Email is already registered",
        }
    }
