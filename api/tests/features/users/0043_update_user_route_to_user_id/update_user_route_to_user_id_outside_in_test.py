# FEATURE: update_user_route_to_user_id — outside-in acceptance test.
#
# Covers: F1, F5, F13, F14, F15 (happy path + forbidden owner check by integer ID).
# Red-state trigger: the current route is PATCH /user/{username} where the path
# param is typed as str.  Calling PATCH /user/{alice_id} (an integer) causes FastAPI
# to bind username="1" (or whatever the PK is), look up a user with that string
# username, find nothing, and return 404 instead of the expected 200 / 403.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}"


async def test_update_user_happy_path(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — owner updates their own name by integer ID; response is 200."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"name": "Alice Updated"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "User updated"}

    # DB state: verify name was persisted via GET /user/{user_id}.
    verify = await async_client.get(f"/api/v1/user/{seeded_alice['id']}")
    assert verify.status_code == 200, verify.text
    assert verify.json()["name"] == "Alice Updated"


async def test_update_user_forbidden_wrong_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """Scenario 2 — bob attempts to patch alice's profile by integer ID; must receive 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.patch(
            _ENDPOINT.format(user_id=seeded_alice["id"]),
            json={"name": "Hacked"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}

    # DB state: alice's name must be unchanged.
    verify = await async_client.get(f"/api/v1/user/{seeded_alice['id']}")
    assert verify.status_code == 200, verify.text
    assert verify.json()["name"] == "Alice Tester"
