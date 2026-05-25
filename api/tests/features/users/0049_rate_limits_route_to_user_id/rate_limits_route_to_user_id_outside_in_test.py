# FEATURE: rate_limits_route_to_user_id — outside-in acceptance test.
#
# Migration slice 0049: route migrated from {username} to {user_id}.
# Covers (per 0049 tests.md):
#   F1, F3, F6, F7 (scenario 1 — happy path)
#   F4, F9         (scenario 2 — unknown user_id → 404)
# Red-state trigger: the pre-migration route is /api/v1/user/{username}/rate_limits,
# so a request carrying an integer id binds username to the id's string form,
# crud_users.get(username="<id>") finds nothing, and the call returns 404 —
# scenario 1's 200 assertion fails RED until the route is migrated to {user_id}
# and the lookup uses id=user_id. (Scenario 2 may already pass in the red state;
# the red signal comes from scenario 1.)
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}/rate_limits"


async def test_rate_limits_happy_path(
    async_client: AsyncClient,
    seeded_user_with_tier: dict,
    seeded_superuser: dict,
) -> None:
    """Scenario 1 — superuser reads a user's rate limits by integer id; tier rows returned."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    target_id = seeded_user_with_tier["id"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=target_id))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == target_id
    assert body["tier_id"] == seeded_user_with_tier["tier_id"]
    assert body["username"] == seeded_user_with_tier["username"]
    assert "name" in body
    assert "email" in body
    assert "profile_image_url" in body

    assert isinstance(body["tier_rate_limits"], list)
    assert len(body["tier_rate_limits"]) >= 1
    names = {entry["name"] for entry in body["tier_rate_limits"]}
    assert seeded_user_with_tier["rate_limit_name"] in names


async def test_rate_limits_unknown_user_returns_404(
    async_client: AsyncClient,
    seeded_superuser: dict,
) -> None:
    """Scenario 2 — unknown user_id returns 404 with the domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_user

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_superuser
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=999999))
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    assert response.status_code == 404, response.text
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}
