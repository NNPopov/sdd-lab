# FEATURE: get_tier — outside-in acceptance test.
#
# Covers: F1, F2, F3, F5, F6, F7, F8 (see requirements.md).
#
# Red-state trigger: features/tiers/get_tier/ does not exist yet.
# GET /tier/{name} is served by the old read_tier handler which uses async_get_db
# (a separate DB connection, not the overridden container session_factory). The
# tier row seeded inside the savepoint transaction is invisible to the old handler
# through async_get_db → the old handler returns 404 instead of 200 → Scenario 1
# assertion on status_code fails.
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"

# Unique prefix ensures no collision with existing DB rows across test runs.
_TIER_NAME = f"oit-get-tier-{uuid.uuid4().hex[:8]}"


async def test_get_tier_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — existing tier; GET /tier/{name} returns 200 with id, name, created_at."""
    from app.bootstrap.container import container as _di_container

    # Seed a tier row inside the savepoint transaction so it is visible to the
    # new adapter (which uses the overridden session_factory) but rolled back
    # at teardown.
    async with _di_container.session_factory()() as session:
        await session.execute(
            text('INSERT INTO "tier" (name, created_at) VALUES (:name, NOW())'),
            {"name": _TIER_NAME},
        )
        await session.commit()

    # Capture the assigned id for assertion.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text('SELECT id FROM "tier" WHERE name = :name'),
            {"name": _TIER_NAME},
        )
        row = result.first()
    assert row is not None, "seeded tier row not found in test transaction"

    response = await async_client.get(f"{_ENDPOINT}/{_TIER_NAME}")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == row.id
    assert body["name"] == _TIER_NAME
    assert "created_at" in body


async def test_get_tier_not_found_returns_404(async_client: AsyncClient) -> None:
    """Scenario 2 — unknown name; GET /tier/{name} returns 404 with domain error body."""
    response = await async_client.get(f"{_ENDPOINT}/nonexistent_tier_xyz")

    assert response.status_code == 404, response.text
    assert response.json() == {
        "error": {
            "code": "notfound",
            "message": "Tier not found",
        }
    }
