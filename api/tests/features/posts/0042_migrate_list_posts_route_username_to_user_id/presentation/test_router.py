# FEATURE: migrate_list_posts_route_username_to_user_id — endpoint integration tests.
#
# Covers: F1 (200 + response shape), F2/F10 (422 on non-integer path),
#         F3 (unauthenticated public view), F4 (author view sees non-approved),
#         F5 (non-author authenticated → public view), F6 (empty for existing
#         user), F7 (unknown user_id → empty, not 404), F9 (pagination),
#         F15/F16 (view selection + query construction), F17 (cache key keyed
#         by user_id).
#
# Real adapter + test Postgres via the slice `async_client` fixture (savepoint
# rollback); Redis is mocked by the fixture (always a cache miss).
import pytest
from httpx import AsyncClient

import app.adapters.cache.redis_cache as _cache_module

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{user_id}/posts"


def _as_author(seeded_author):
    """Context manager-ish helper: override get_optional_user to the seeded owner."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: {
        "id": seeded_author.id,
        "username": "alicepost",
    }
    return _fastapi_app, get_optional_user


# ── F1, F3, F18: unauthenticated public view ──────────────────────────────────


async def test_public_view_lists_only_approved(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))

    assert response.status_code == 200, response.text
    body = response.json()
    assert set(body.keys()) == {"items", "total_count", "page", "items_per_page"}
    assert body["total_count"] == 1
    assert len(body["items"]) == 1
    item = body["items"][0]
    assert item["status"] == "approved"
    assert item["created_by_user_id"] == seeded_author.id
    assert item["username"] == "alicepost"


# ── F4, F15, F16: authenticated owner sees non-approved posts ─────────────────


async def test_author_view_includes_pending(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    app_, dep = _as_author(seeded_author)
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))
    finally:
        del app_.dependency_overrides[dep]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["total_count"] == 2
    assert {item["status"] for item in body["items"]} == {"approved", "pending"}


# ── F5: authenticated non-owner gets the public view ──────────────────────────


async def test_non_author_authenticated_sees_only_approved(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_optional_user

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: {
        "id": seeded_author.id + 999_999,
        "username": "someoneelse",
    }
    try:
        response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["total_count"] == 1
    assert all(item["status"] == "approved" for item in body["items"])


# ── F6: existing user with no posts → empty ───────────────────────────────────


async def test_existing_user_no_posts_returns_empty(
    async_client: AsyncClient,
    seeded_author,
) -> None:
    response = await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0
    assert body["page"] == 1
    assert body["items_per_page"] == 10


# ── F7: unknown user_id → empty, not 404 ──────────────────────────────────────


async def test_unknown_user_id_returns_empty(async_client: AsyncClient) -> None:
    response = await async_client.get(_ENDPOINT.format(user_id=999_999))

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0


# ── F2, F10: non-integer path segment → 422 ───────────────────────────────────


async def test_non_integer_user_id_returns_422(async_client: AsyncClient) -> None:
    response = await async_client.get("/api/v1/not-an-integer/posts")
    assert response.status_code == 422, response.text


# ── F9: pagination honoured ───────────────────────────────────────────────────


async def test_pagination_author_view(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    app_, dep = _as_author(seeded_author)
    try:
        page1 = await async_client.get(
            _ENDPOINT.format(user_id=seeded_author.id),
            params={"page": 1, "items_per_page": 1},
        )
        page2 = await async_client.get(
            _ENDPOINT.format(user_id=seeded_author.id),
            params={"page": 2, "items_per_page": 1},
        )
    finally:
        del app_.dependency_overrides[dep]

    assert page1.status_code == 200
    assert page2.status_code == 200
    b1, b2 = page1.json(), page2.json()
    assert b1["total_count"] == 2
    assert b1["page"] == 1
    assert b1["items_per_page"] == 1
    assert len(b1["items"]) == 1
    assert len(b2["items"]) == 1
    assert b1["items"][0]["id"] != b2["items"][0]["id"]


# ── F17: cache key keyed by user_id ───────────────────────────────────────────


async def test_cache_key_prefixed_by_user_id(
    async_client: AsyncClient,
    seeded_author,
    seeded_author_posts,
) -> None:
    await async_client.get(_ENDPOINT.format(user_id=seeded_author.id))

    # The @cache decorator writes the response under
    # f"{user_id}_posts:{view}:...:{resource_id}". resource_id_name="user_id".
    assert _cache_module.client.set.await_args is not None
    cache_key = _cache_module.client.set.await_args.args[0]
    assert cache_key.startswith(f"{seeded_author.id}_posts:"), cache_key
