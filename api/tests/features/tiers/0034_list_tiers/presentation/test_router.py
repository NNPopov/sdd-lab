# FEATURE: list_tiers — endpoint integration tests.
#
# Covers: F1 (200 + shape), F2 (empty DB → 200 empty), F3 (page=0 → 422),
#         F4 (items_per_page=0 or >100 → 422), F5 (no auth → 200),
#         F6 (id, name, created_at fields), F7 (shape keys), F11 (pagination truncation).
#
# Uses async_client + _clean_tiers from the slice conftest (autouse cleanup).
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tiers"


async def _seed_tiers(async_client: AsyncClient, names: list[str]) -> None:
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        await session.execute(
            text('INSERT INTO "tier" (name, created_at) VALUES (:name, NOW())'),
            [{"name": n} for n in names],
        )
        await session.commit()


async def test_200_with_correct_shape(async_client: AsyncClient) -> None:
    """F1, F7: 200 with contracted top-level and item fields."""
    await _seed_tiers(async_client, ["free", "pro"])

    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}
    assert body["total_count"] == 2
    assert len(body["items"]) == 2


async def test_each_item_has_required_fields(async_client: AsyncClient) -> None:
    """F6: each item carries id (int), name (str), created_at."""
    await _seed_tiers(async_client, ["basic"])

    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    item = response.json()["items"][0]
    assert isinstance(item["id"], int)
    assert isinstance(item["name"], str)
    assert "created_at" in item


async def test_empty_database_returns_200_with_empty_items(async_client: AsyncClient) -> None:
    """F2: no tiers → 200 with items=[] and total_count=0."""
    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert body == {"items": [], "total_count": 0, "page": 1, "items_per_page": 10}


async def test_no_auth_required(async_client: AsyncClient) -> None:
    """F5: unauthenticated request returns 200."""
    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200


async def test_page_zero_returns_422(async_client: AsyncClient) -> None:
    """F3: page=0 rejected by ge=1 constraint."""
    response = await async_client.get(_ENDPOINT, params={"page": 0})

    assert response.status_code == 422


async def test_items_per_page_zero_returns_422(async_client: AsyncClient) -> None:
    """F4: items_per_page=0 rejected by ge=1 constraint."""
    response = await async_client.get(_ENDPOINT, params={"items_per_page": 0})

    assert response.status_code == 422


async def test_items_per_page_over_100_returns_422(async_client: AsyncClient) -> None:
    """F4: items_per_page=101 rejected by le=100 constraint."""
    response = await async_client.get(_ENDPOINT, params={"items_per_page": 101})

    assert response.status_code == 422


async def test_pagination_truncates_to_items_per_page(async_client: AsyncClient) -> None:
    """F11: when items_per_page < total, only items_per_page rows returned; total_count is full count."""
    await _seed_tiers(async_client, ["a", "b", "c"])

    response = await async_client.get(_ENDPOINT, params={"page": 1, "items_per_page": 2})

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 3
    assert len(body["items"]) == 2


async def test_items_ordered_by_id_ascending(async_client: AsyncClient) -> None:
    """F10: items are returned ordered by id ascending."""
    await _seed_tiers(async_client, ["first", "second", "third"])

    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    names = [item["name"] for item in response.json()["items"]]
    assert names == ["first", "second", "third"]
