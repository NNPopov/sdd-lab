# FEATURE: list_all_posts_visibility — outside-in acceptance test.
#
# Covers: F1 (all scenarios — HTTP 200 for every caller)
#         F2 (scenario 1 — unauthenticated → only approved)
#         F3 (scenario 2 — regular user → only approved)
#         F4 (scenario 3 — moderator → all posts regardless of status)
#         F6 (all scenarios — total_count reflects filtered/unfiltered count)
#         F8 (all scenarios — status field present on every item)
#
# Red-state trigger: ListAllPostsAdapter has no visibility filter.
# Scenario 1 receives total_count=3 (all posts) instead of 1 (approved only),
# failing on the count assertion.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/posts"
_EXPECTED_ITEM_FIELDS = {
    "id",
    "title",
    "text",
    "media_url",
    "created_at",
    "created_by_user_id",
    "username",
    "status",
}


async def test_unauthenticated_caller_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    posts_data: list,
) -> None:
    """Scenario 1 — no Authorization header → only the approved post is returned.

    Three posts exist: one approved, two pending_review. An unauthenticated
    caller must receive exactly the approved one.
    """
    response = await async_client.get(_ENDPOINT)

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 1, f"unauthenticated caller: expected 1 approved post, got {body['total_count']}"
    assert len(body["items"]) == 1

    item = body["items"][0]
    assert item["status"] == "approved", f"expected approved, got {item['status']!r}"
    assert _EXPECTED_ITEM_FIELDS.issubset(set(item.keys())), f"item missing fields; got {set(item.keys())}"


async def test_regular_user_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    posts_data: list,
) -> None:
    """Scenario 2 — authenticated as alice (regular user) → only approved post.

    Alice has no moderator or superuser privileges. She must receive the same
    public view as an unauthenticated caller.
    """
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: alice_user
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 1, f"regular user: expected 1 approved post, got {body['total_count']}"
    assert len(body["items"]) == 1
    assert body["items"][0]["status"] == "approved"

    for item in body["items"]:
        assert "status" in item, f"status field missing on item {item.get('id')}"


async def test_moderator_sees_all_posts_regardless_of_status(
    async_client: AsyncClient,
    mod_user: dict,
    posts_data: list,
) -> None:
    """Scenario 3 — authenticated as mod (is_moderator=True) → all 3 posts returned.

    A moderator must receive the unfiltered list, including pending_review posts,
    so they have full visibility into the global feed.
    """
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: mod_user
    try:
        response = await async_client.get(_ENDPOINT)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 3, f"moderator: expected all 3 posts, got {body['total_count']}"
    assert len(body["items"]) == 3

    statuses = {item["status"] for item in body["items"]}
    assert "approved" in statuses, "moderator view must include the approved post"
    assert "pending_review" in statuses, "moderator view must include pending_review posts"

    for item in body["items"]:
        assert _EXPECTED_ITEM_FIELDS.issubset(set(item.keys())), f"item missing fields; got {set(item.keys())}"
