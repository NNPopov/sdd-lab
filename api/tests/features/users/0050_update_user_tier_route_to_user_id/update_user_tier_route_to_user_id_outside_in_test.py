# FEATURE: update_user_tier_route_to_user_id — outside-in acceptance test.
#
# Migration slice 0050: route migrated from {username} to {user_id}.
# Covers (per 0050 tests.md):
#   F1, F2, F3, F6, F7 (scenario 1 — happy path; PATCH then GET verifies)
#   F4, F9             (scenario 2 — unknown user_id → 404)
# Red-state trigger: the pre-migration route is /api/v1/user/{username}/tier,
# so a request carrying an integer id binds username to the id's string form,
# crud_users.get(username="<id>") finds nothing, and the call returns 404 —
# scenario 1's 200 assertion fails RED until the route is migrated to {user_id}
# and both the lookup and the update use id=user_id. (Scenario 2 may already
# pass in the red state; the red signal comes from scenario 1.)
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_PATCH_ENDPOINT = "/api/v1/user/{user_id}/tier"
_GET_ENDPOINT = "/api/v1/user/{user_id}/tier"


async def test_update_user_tier_happy_path(
    async_client: AsyncClient,
    seeded_user_and_tier: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 1 — superuser updates a user's tier by integer id; GET reflects the change."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    target_id = seeded_user_and_tier["id"]
    tier_id = seeded_user_and_tier["tier_id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        patch_response = await async_client.patch(
            _PATCH_ENDPOINT.format(user_id=target_id),
            json={"tier_id": tier_id},
        )
        get_response = await async_client.get(_GET_ENDPOINT.format(user_id=target_id))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert patch_response.status_code == 200, patch_response.text
    assert patch_response.json() == {"message": f"User {seeded_user_and_tier['name']} Tier updated"}

    assert get_response.status_code == 200, get_response.text
    get_body = get_response.json()
    assert get_body is not None
    assert get_body["tier_id"] == tier_id
    assert get_body["tier_name"] == seeded_user_and_tier["tier_name"]


async def test_update_user_tier_unknown_user_returns_404(
    async_client: AsyncClient,
    seeded_user_and_tier: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 2 — unknown user_id returns 404 with the domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    tier_id = seeded_user_and_tier["tier_id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.patch(
            _PATCH_ENDPOINT.format(user_id=999999),
            json={"tier_id": tier_id},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}
