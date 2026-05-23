# FEATURE: create_tier — outside-in acceptance test.
#
# Covers: F1, F5, F8, F10 (see requirements.md).
#
# Red-state trigger: features/tiers/create_tier/ does not exist yet.
# POST /tier is handled by the old write_tier handler which uses async_get_db
# (not the container's session_factory override), so the tier row written by
# Scenario 1 is invisible in the test-transaction DB assertion → assertion fails.
# For Scenario 2, the second POST returns 409 but with a different message
# ("Tier Name not available" vs "Tier name already exists") → body assertion fails.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"


async def test_create_tier_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — superuser creates a tier; response is 201 with correct fields."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.post(_ENDPOINT, json={"name": "gold"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 201, response.text
    body = response.json()

    assert body["name"] == "gold"
    assert isinstance(body["id"], int)
    assert "created_at" in body

    # DB assertion: row is visible in the test transaction (only true with new slice).
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT name FROM "tier" WHERE name = :n'),
            {"n": "gold"},
        )
        row = result.first()
        assert row is not None, "tier row not found in test transaction after create"
        assert row.name == "gold"


async def test_create_tier_duplicate_name_returns_409(async_client: AsyncClient) -> None:
    """Scenario 2 — second POST with the same name returns 409 with domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        # First call — establishes the tier.
        first = await async_client.post(_ENDPOINT, json={"name": "gold"})
        assert first.status_code == 201, first.text

        # Second call — same name must be rejected.
        second = await async_client.post(_ENDPOINT, json={"name": "gold"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert second.status_code == 409, second.text
    assert second.json() == {
        "error": {
            "code": "duplicatevalue",
            "message": "Tier name already exists",
        }
    }
