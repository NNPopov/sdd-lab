# FEATURE: list_users — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5, F6, F7, F8.
# Uses async_client + make_user from 0003_list_users/conftest.py (real Postgres).
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/users"


async def test_get_users_returns_200_with_correct_schema(
    async_client: AsyncClient,
    make_user,
) -> None:
    """F1, F2, F3: 200 response with the contracted top-level and item fields."""
    await make_user()

    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}
    assert isinstance(body["items"], list)
    for item in body["items"]:
        assert {"id", "name", "username", "email", "profile_image_url", "tier_id"}.issubset(item.keys())


async def test_soft_deleted_user_absent_from_response(
    async_client: AsyncClient,
    make_user,
) -> None:
    """F4: soft-deleted user excluded from both items and total_count."""
    active = await make_user()
    deleted = await make_user(is_deleted=True)

    response = await async_client.get(_ENDPOINT, params={"items_per_page": 500})
    assert response.status_code == 200
    body = response.json()

    usernames = {item["username"] for item in body["items"]}
    assert active.username in usernames
    assert deleted.username not in usernames
    assert body["total_count"] == len(body["items"])


async def test_page_zero_returns_422(async_client: AsyncClient) -> None:
    """F5: page=0 rejected with 422 by Pydantic ge=1."""
    response = await async_client.get(_ENDPOINT, params={"page": 0})
    assert response.status_code == 422


async def test_items_per_page_zero_returns_422(async_client: AsyncClient) -> None:
    """F6: items_per_page=0 rejected with 422 by Pydantic ge=1."""
    response = await async_client.get(_ENDPOINT, params={"items_per_page": 0})
    assert response.status_code == 422


async def test_default_page_is_1(
    async_client: AsyncClient,
    make_user,
) -> None:
    """F7: omitting page defaults to page=1."""
    await make_user()
    response = await async_client.get(_ENDPOINT)
    assert response.status_code == 200
    assert response.json()["page"] == 1


async def test_default_items_per_page_is_10(
    async_client: AsyncClient,
    make_user,
) -> None:
    """F8: omitting items_per_page defaults to 10."""
    await make_user()
    response = await async_client.get(_ENDPOINT)
    assert response.status_code == 200
    assert response.json()["items_per_page"] == 10


async def test_pagination_returns_correct_subset(
    async_client: AsyncClient,
    make_user,
) -> None:
    """F9: page 2 with items_per_page=3 returns a non-overlapping subset."""
    for _ in range(7):
        await make_user()

    page1 = await async_client.get(_ENDPOINT, params={"page": 1, "items_per_page": 3})
    page2 = await async_client.get(_ENDPOINT, params={"page": 2, "items_per_page": 3})

    assert page1.status_code == 200
    assert page2.status_code == 200

    names1 = {item["username"] for item in page1.json()["items"]}
    names2 = {item["username"] for item in page2.json()["items"]}
    assert names1.isdisjoint(names2)
    assert len(page2.json()["items"]) == 3
