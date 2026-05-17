# FEATURE: list_all_posts_visibility — endpoint integration tests.
#
# Covers: F1 (HTTP 200 for all caller types)
#         F2 (unauthenticated → only approved)
#         F3 (regular user → only approved)
#         F4 (moderator → all posts)
#         F5 (superuser → all posts)
#         F7 (no approved posts, non-privileged → empty list)
#         F8 (status field present on every response item)
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts"


async def test_unauthenticated_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    posts_data: list,
) -> None:
    """F1, F2: no Authorization header → HTTP 200, only the approved post returned."""
    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["status"] == "approved"


async def test_regular_user_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    posts_data: list,
) -> None:
    """F1, F3: authenticated as a regular user → only approved post returned."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: alice_user
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert len(body["items"]) == 1
    assert body["items"][0]["status"] == "approved"


async def test_moderator_sees_all_posts(
    async_client: AsyncClient,
    mod_user: dict,
    posts_data: list,
) -> None:
    """F1, F4: authenticated as a moderator → all posts returned regardless of status."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: mod_user
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 3
    assert len(body["items"]) == 3
    statuses = {item["status"] for item in body["items"]}
    assert "approved" in statuses
    assert "pending_review" in statuses


async def test_superuser_sees_all_posts(
    async_client: AsyncClient,
    alice_user: dict,
    posts_data: list,
) -> None:
    """F1, F5: authenticated as a superuser → all posts returned regardless of status."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    superuser = {**alice_user, "is_superuser": True, "is_moderator": False}
    _fastapi_app.dependency_overrides[get_optional_user] = lambda: superuser
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 3
    assert len(body["items"]) == 3


async def test_zero_approved_posts_returns_empty_for_non_privileged(
    async_client: AsyncClient,
    alice_user: dict,
) -> None:
    """F7: no approved posts exist, non-privileged caller → HTTP 200, empty items."""
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

    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200
    body = response.json()
    assert body["items"] == []
    assert body["total_count"] == 0


async def test_status_field_present_on_every_response_item(
    async_client: AsyncClient,
    mod_user: dict,
    posts_data: list,
) -> None:
    """F8: status field is present on every item for the privileged view."""
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: mod_user
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200
    body = response.json()
    for item in body["items"]:
        assert "status" in item, f"status field missing on item {item.get('id')}"
