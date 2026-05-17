# FEATURE: list_posts_visibility — endpoint integration tests.
#
# Covers: F1 (unauthenticated → only approved)
#         F2 (different authenticated user → only approved)
#         F3 (author → all posts regardless of status)
#         F4 (no approved posts, non-author → HTTP 200 empty list)
#         F5 (status field present on every response item)
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/posts"


async def test_unauthenticated_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    alice_posts: list,
) -> None:
    """F1: no Authorization header → HTTP 200, only the approved post returned."""
    response = await async_client.get(_ENDPOINT.format(username=alice_user["username"]))

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["status"] == "approved"


async def test_different_authenticated_user_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    bob_user: dict,
    alice_posts: list,
) -> None:
    """F2: authenticated as a user who is not the author → only approved post returned."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: bob_user
    try:
        response = await async_client.get(_ENDPOINT.format(username=alice_user["username"]))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["status"] == "approved"


async def test_author_sees_all_posts_regardless_of_status(
    async_client: AsyncClient,
    alice_user: dict,
    alice_posts: list,
) -> None:
    """F3: authenticated as the author → HTTP 200, all posts (any status) returned."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: alice_user
    try:
        response = await async_client.get(_ENDPOINT.format(username=alice_user["username"]))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 3
    assert len(body["items"]) == 3
    statuses = {item["status"] for item in body["items"]}
    assert "approved" in statuses
    assert "pending_review" in statuses


async def test_zero_approved_posts_returns_empty_for_non_author(
    async_client: AsyncClient,
    alice_user: dict,
) -> None:
    """F4: target user has no approved posts and caller is not the author → empty list."""
    from app.adapters.db.models.post import Post
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        post = Post(
            created_by_user_id=alice_user["id"],
            title="Pending Only",
            text="This post is pending review.",
        )
        session.add(post)
        await session.commit()

    response = await async_client.get(_ENDPOINT.format(username=alice_user["username"]))

    assert response.status_code == 200
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0


async def test_status_field_present_in_every_response_item(
    async_client: AsyncClient,
    alice_user: dict,
    alice_posts: list,
) -> None:
    """F5: status field is present on every item in the response."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: alice_user
    try:
        response = await async_client.get(_ENDPOINT.format(username=alice_user["username"]))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    for item in body["items"]:
        assert "status" in item, f"status field missing on item {item.get('id')}"
