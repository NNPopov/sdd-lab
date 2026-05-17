# FEATURE: get_user_tier — outside-in acceptance test.
#
# Covers: F1, F2, F3, F4, F6, F17 (see requirements.md).
# Red-state trigger: the new slice (GetUserTierUseCase / GetUserTierAdapter)
# does not yet exist. The old free function reads through async_get_db which
# bypasses the container session_factory override, so seeded data is invisible
# to it and scenario 1 fails with 404 instead of the expected 200.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{username}/tier"


async def test_get_user_tier_happy_path(
    async_client: AsyncClient,
    seeded_user_with_tier,
) -> None:
    """Scenario 1 — user with tier returns 200 with all three contracted fields."""
    tier, _user = seeded_user_with_tier

    response = await async_client.get(_ENDPOINT.format(username="tieruser"))

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
    """Scenario 2 — non-existent username returns 404."""
    response = await async_client.get(_ENDPOINT.format(username="ghost_xyz"))

    assert response.status_code == 404, response.text
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"
