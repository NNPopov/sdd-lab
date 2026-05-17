# FEATURE: update_user — outside-in acceptance test.
#
# Covers: F1, F3, F8, F13 (happy path + forbidden owner).
# Red-state trigger: the old patch_user implementation uses async_get_db directly
# (bypasses the container session_factory override) and therefore cannot see
# users seeded in the test transaction → returns 404 instead of the expected
# 200 / 403.  Once the new UpdateUserUseCase / UpdateUserAdapter slice replaces
# it, the container-scoped session sees the seeded data and the tests turn green.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{username}"


async def test_update_user_happy_path(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — owner updates their own name; response is 200 and DB row is mutated."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"name": "Alice Updated"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "User updated"}

    # DB state: verify name was persisted by reading back through the GET endpoint.
    verify = await async_client.get(_ENDPOINT.format(username="alice"))
    assert verify.status_code == 200, verify.text
    assert verify.json()["name"] == "Alice Updated"


async def test_update_user_forbidden_wrong_owner(
    async_client: AsyncClient,
    seeded_alice: dict,
    seeded_bob: dict,
) -> None:
    """Scenario 2 — bob attempts to patch alice's profile; must receive 403."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_bob
    try:
        response = await async_client.patch(
            _ENDPOINT.format(username="alice"),
            json={"name": "Hacked"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 403, response.text
    assert response.json() == {"error": {"code": "forbidden", "message": ""}}

    # DB state: alice's name must be unchanged.
    verify = await async_client.get(_ENDPOINT.format(username="alice"))
    assert verify.status_code == 200, verify.text
    assert verify.json()["name"] == "Alice Tester"
