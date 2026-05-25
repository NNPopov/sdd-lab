# FEATURE: get_user_tier — outside-in acceptance test.
#
# Covers: F1, F4, F5, F8, F9 (see
# specs/features/users/0048_get_user_tier_route_to_user_id/requirements.md).
# Red-state trigger (slice 0048): the route still matches `{username}`, so a
# request to /api/v1/user/{int}/tier binds username="<int>". The adapter then
# looks up User.username == "<int>", which does not match the seeded user
# "tieruser", and scenario 1 returns 404 instead of the expected 200. The test
# turns green once the route, query, and adapter look up by integer User.id.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}/tier"


async def test_get_user_tier_happy_path(
    async_client: AsyncClient,
    seeded_user_with_tier,
) -> None:
    """Scenario 1 — user resolved by integer id returns 200 with the tier body."""
    tier, user = seeded_user_with_tier

    response = await async_client.get(_ENDPOINT.format(user_id=user.id))

    assert response.status_code == 200, response.text
    body = response.json()

    assert body is not None, "Expected a JSON object, got null"
    assert body["tier_id"] == tier.id
    assert body["tier_name"] == "pro"
    assert "tier_created_at" in body

    assert set(body.keys()) == {"tier_id", "tier_name", "tier_created_at"}, (
        f"Unexpected response keys: {set(body.keys())}"
    )


async def test_get_user_tier_user_not_found(
    async_client: AsyncClient,
) -> None:
    """Scenario 2 — unknown user_id returns 404."""
    response = await async_client.get(_ENDPOINT.format(user_id=999999))

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"
