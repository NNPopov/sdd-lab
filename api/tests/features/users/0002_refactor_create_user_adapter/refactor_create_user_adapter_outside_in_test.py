# FEATURE: refactor_create_user_adapter — outside-in regression test.
#
# This test verifies that the refactored adapter and port produce the same
# end-to-end HTTP behavior as before the refactor.
# Covers: F7 (success → 201), F8 use-case path (duplicate email → 409).
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user"

_VALID_PAYLOAD: dict[str, str] = {
    "name": "Bob Refactor",
    "username": "bobrefactor",
    "email": "bob.refactor@example.com",
    "password": "Str0ng!pw",
}


async def test_create_user_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — valid new user returns 201 with CreateUserResponse shape."""
    response = await async_client.post(_ENDPOINT, json=_VALID_PAYLOAD)

    assert response.status_code == 201, response.text

    body = response.json()
    assert isinstance(body["id"], int)
    assert body["name"] == "Bob Refactor"
    assert body["username"] == "bobrefactor"
    assert body["email"] == "bob.refactor@example.com"

    # Confirm persistence: a second identical POST must return 409.
    confirm = await async_client.post(_ENDPOINT, json=_VALID_PAYLOAD)
    assert confirm.status_code == 409, "Expected 409 on duplicate — row was not actually persisted."


async def test_create_user_duplicate_email(async_client: AsyncClient) -> None:
    """Scenario 2 — duplicate email returns 409."""
    seed = await async_client.post(_ENDPOINT, json=_VALID_PAYLOAD)
    assert seed.status_code == 201, f"Seed step failed: {seed.text}"

    duplicate = await async_client.post(
        _ENDPOINT,
        json={**_VALID_PAYLOAD, "username": "bobrefactor_clone"},
    )

    assert duplicate.status_code == 409, duplicate.text
    assert duplicate.json() == {
        "error": {
            "code": "duplicatevalue",
            "message": "Email is already registered",
        }
    }
