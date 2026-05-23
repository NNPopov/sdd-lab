# FEATURE: get_tier — endpoint integration tests.
#
# Covers: F1, F2, F3, F4.
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"
_TIER_NAME = f"rt-get-tier-{uuid.uuid4().hex[:8]}"


async def test_get_tier_returns_200_with_correct_schema(async_client: AsyncClient) -> None:
    """F1, F2, F4 — existing tier; GET /tier/{name} returns 200 with id, name, created_at."""
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

    assert row is not None
    response = await async_client.get(f"{_ENDPOINT}/{_TIER_NAME}")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["id"] == row.id
    assert body["name"] == _TIER_NAME
    assert "created_at" in body


async def test_get_tier_not_found_returns_404(async_client: AsyncClient) -> None:
    """F3 — unknown name; GET /tier/{name} returns 404 with domain error body."""
    response = await async_client.get(f"{_ENDPOINT}/__nonexistent_name__")

    assert response.status_code == 404, response.text
    assert response.json() == {
        "error": {
            "code": "notfound",
            "message": "Tier not found",
        }
    }


async def test_get_tier_unauthenticated_returns_200_for_existing_tier(async_client: AsyncClient) -> None:
    """F4 — no auth header; existing tier returns 200 (endpoint is public)."""
    from app.bootstrap.container import container as _di_container

    unique_name = f"rt-public-{uuid.uuid4().hex[:8]}"
    async with _di_container.session_factory()() as session:
        await session.execute(
            text('INSERT INTO "tier" (name, created_at) VALUES (:name, NOW())'),
            {"name": unique_name},
        )
        await session.commit()

    response = await async_client.get(f"{_ENDPOINT}/{unique_name}")
    assert response.status_code == 200, response.text
