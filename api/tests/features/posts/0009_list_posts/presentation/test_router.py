# FEATURE: list_posts — endpoint integration tests.
#
# Covers: F1 (200 + schema), F2 (pagination metadata echoed), F3 (total_count),
#         F4 (soft-deleted post excluded), F5 (soft-deleted user's posts excluded),
#         F6 (default page=1), F7 (default items_per_page=10), F8 (items_per_page > 100 → 422),
#         F9 (pagination subset), F10 (unknown username → 200 empty).
#
# Uses async_client (with Redis mock), make_user, make_post from the slice conftest.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/posts"


async def test_200_with_correct_schema(
    async_client: AsyncClient,
    make_user,
    make_post,
) -> None:
    """F1, F2: 200 with contracted top-level and item fields."""
    user = await make_user()
    await make_post(user_id=user.id)

    response = await async_client.get(_ENDPOINT.format(username=user.username))

    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}
    assert isinstance(body["items"], list)
    assert len(body["items"]) == 1
    item = body["items"][0]
    assert {"id", "title", "text", "media_url", "created_at", "created_by_user_id", "username"}.issubset(item.keys())
    assert item["username"] == user.username


async def test_unknown_username_returns_empty(async_client: AsyncClient) -> None:
    """F10: username not in DB → 200 with empty items and total_count 0."""
    response = await async_client.get(_ENDPOINT.format(username="nobody_here"))

    assert response.status_code == 200
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0


async def test_soft_deleted_post_absent_from_response(
    async_client: AsyncClient,
    make_user,
    make_post,
) -> None:
    """F4: soft-deleted post is excluded from items and total_count."""
    user = await make_user()
    active_post = await make_post(user_id=user.id)
    await make_post(user_id=user.id, is_deleted=True)

    response = await async_client.get(
        _ENDPOINT.format(username=user.username),
        params={"items_per_page": 100},
    )

    assert response.status_code == 200
    body = response.json()
    ids = [item["id"] for item in body["items"]]
    assert active_post.id in ids
    assert body["total_count"] == 1


async def test_soft_deleted_user_posts_absent(
    async_client: AsyncClient,
    make_user,
    make_post,
) -> None:
    """F5: posts belonging to a soft-deleted user are excluded."""
    deleted_user = await make_user(is_deleted=True)
    await make_post(user_id=deleted_user.id)

    response = await async_client.get(_ENDPOINT.format(username=deleted_user.username))

    assert response.status_code == 200
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0


async def test_page_zero_returns_422(async_client: AsyncClient) -> None:
    """F5 validation: page=0 rejected by ge=1 constraint."""
    response = await async_client.get(
        _ENDPOINT.format(username="anyone"),
        params={"page": 0},
    )
    assert response.status_code == 422


async def test_items_per_page_over_100_returns_422(async_client: AsyncClient) -> None:
    """F8: items_per_page=101 rejected by le=100 constraint."""
    response = await async_client.get(
        _ENDPOINT.format(username="anyone"),
        params={"items_per_page": 101},
    )
    assert response.status_code == 422


async def test_default_page_is_1(
    async_client: AsyncClient,
    make_user,
    make_post,
) -> None:
    """F6: omitting page defaults to 1."""
    user = await make_user()
    await make_post(user_id=user.id)

    response = await async_client.get(_ENDPOINT.format(username=user.username))

    assert response.status_code == 200
    assert response.json()["page"] == 1


async def test_default_items_per_page_is_10(
    async_client: AsyncClient,
    make_user,
    make_post,
) -> None:
    """F7: omitting items_per_page defaults to 10."""
    user = await make_user()
    await make_post(user_id=user.id)

    response = await async_client.get(_ENDPOINT.format(username=user.username))

    assert response.status_code == 200
    assert response.json()["items_per_page"] == 10


async def test_pagination_returns_non_overlapping_subsets(
    async_client: AsyncClient,
    make_user,
    make_post,
) -> None:
    """F9: page 1 and page 2 with items_per_page=3 return disjoint sets."""
    user = await make_user()
    for _ in range(7):
        await make_post(user_id=user.id)

    page1 = await async_client.get(
        _ENDPOINT.format(username=user.username),
        params={"page": 1, "items_per_page": 3},
    )
    page2 = await async_client.get(
        _ENDPOINT.format(username=user.username),
        params={"page": 2, "items_per_page": 3},
    )

    assert page1.status_code == 200
    assert page2.status_code == 200
    ids1 = {item["id"] for item in page1.json()["items"]}
    ids2 = {item["id"] for item in page2.json()["items"]}
    assert ids1.isdisjoint(ids2)
    assert len(page2.json()["items"]) == 3
