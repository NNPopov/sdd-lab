# FEATURE: list_tiers — outside-in acceptance test.
#
# Covers: F1, F2, F6, F7, F10 (see requirements.md).
#
# Red-state trigger: features/tiers/list_tiers/ does not exist yet.
# GET /tiers is handled by the old read_tiers handler which returns FastCRUD's
# PaginatedListResponse shape (keys: data, total_count, has_more, page,
# items_per_page). The assertions below expect the new shape (items, total_count,
# page, items_per_page — no data, no has_more), so both scenarios fail as
# AssertionError until the new slice is implemented.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tiers"


async def test_list_tiers_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — two seeded tiers; GET /tiers returns 200 with correct paginated shape."""
    from app.bootstrap.container import container as _di_container

    # Seed two tier rows inside the savepoint transaction so they are visible
    # to the adapter (which shares the overridden session_factory) but are
    # rolled back at teardown, leaving the DB clean.
    async with _di_container.session_factory()() as session:
        await session.execute(
            text('INSERT INTO "tier" (name, created_at) VALUES (:name, NOW())'),
            [{"name": "free"}, {"name": "pro"}],
        )
        await session.commit()

    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200, response.text
    body = response.json()

    # Shape: exactly these four keys, no 'data', no 'has_more'.
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}
    assert body["total_count"] == 2
    assert body["page"] == 1
    assert body["items_per_page"] == 10
    assert len(body["items"]) == 2

    # Items ordered by id ascending (free was inserted first).
    names = [item["name"] for item in body["items"]]
    assert names == ["free", "pro"]

    # Each item has the required fields.
    for item in body["items"]:
        assert isinstance(item["id"], int)
        assert isinstance(item["name"], str)
        assert "created_at" in item


async def test_list_tiers_empty_database_returns_200(async_client: AsyncClient) -> None:
    """Scenario 2 — no tiers in DB; GET /tiers returns 200 with empty items list."""
    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200, response.text
    body = response.json()

    assert body == {"items": [], "total_count": 0, "page": 1, "items_per_page": 10}
