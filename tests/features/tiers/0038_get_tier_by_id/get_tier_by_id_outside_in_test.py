# FEATURE: get_tier_by_id — outside-in acceptance test.
#
# Covers: F1, F2, F4, F5, F6, F7, F8 (see requirements.md).
#
# Red-state trigger: the current router serves GET /tier/{name} where name: str.
# Calling GET /tier/<integer_id> matches the existing route with name="<id>",
# queries WHERE Tier.name == "<id>", finds nothing, and returns 404 instead of
# 200. Scenario 1's status_code assertion fails → test is RED.
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"
_TIER_NAME = f"oit-gettierbyid-{uuid.uuid4().hex[:8]}"


async def test_get_tier_by_id_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — existing tier; GET /tier/{id} returns 200 with id, name, created_at."""
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        await session.execute(
            text('INSERT INTO "tier" (name, created_at) VALUES (:name, NOW())'),
            {"name": _TIER_NAME},
        )
        await session.commit()
        row = (
            await session.execute(
                text('SELECT id FROM "tier" WHERE name = :name'),
                {"name": _TIER_NAME},
            )
        ).first()

    assert row is not None, "seeded tier row not found in test transaction"

    response = await async_client.get(f"{_ENDPOINT}/{row.id}")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == row.id
    assert body["name"] == _TIER_NAME
    assert "created_at" in body


async def test_get_tier_by_id_not_found_returns_404(async_client: AsyncClient) -> None:
    """Scenario 2 — non-existent id; GET /tier/999999 returns 404 with domain error body."""
    response = await async_client.get(f"{_ENDPOINT}/999999")

    assert response.status_code == 404, response.text
    assert response.json() == {
        "error": {
            "code": "notfound",
            "message": "Tier not found",
        }
    }
