# FEATURE: list_posts_visibility — outside-in acceptance test.
#
# Covers: F1 (scenario 1 — unauthenticated → only approved)
#         F2 (scenario 3 — different authenticated user → only approved)
#         F3 (scenario 2 — author → all posts regardless of status)
#         F5 (all scenarios — status field present on every item)
#         F6 (scenario 1 — existing response fields unchanged)
#
# Red-state trigger: the list_posts adapter has no visibility filter and
# PostItem / PostItemSchema have no status field. Scenario 1 returns
# total_count=3 instead of 1, failing immediately on the count assertion.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/{username}/posts"
_ALICE_USERNAME = "oit21alice"
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
    alice_posts: list,
) -> None:
    """Scenario 1 — no Authorization header → only the approved post is returned.

    alice has 3 posts: one approved, two pending_review. An unauthenticated
    caller must receive exactly the approved one.
    """
    response = await async_client.get(_ENDPOINT.format(username=_ALICE_USERNAME))

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 1, f"expected 1 approved post for unauthenticated caller, got {body['total_count']}"
    assert len(body["items"]) == 1

    item = body["items"][0]
    assert item["status"] == "approved"
    # All standard fields (including new status) must be present.
    assert _EXPECTED_ITEM_FIELDS.issubset(set(item.keys())), f"item missing fields; got {set(item.keys())}"


async def test_author_sees_all_posts_regardless_of_status(
    async_client: AsyncClient,
    alice_user: dict,
    alice_posts: list,
) -> None:
    """Scenario 2 — authenticated as alice (the author) → all 3 posts returned.

    The author view must include pending_review posts as well as approved ones
    so alice can track her moderation queue.
    """
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: alice_user
    try:
        response = await async_client.get(_ENDPOINT.format(username=_ALICE_USERNAME))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 3, f"expected all 3 posts for the author, got {body['total_count']}"
    assert len(body["items"]) == 3

    statuses = {item["status"] for item in body["items"]}
    assert "approved" in statuses, "author view must include the approved post"
    assert "pending_review" in statuses, "author view must include pending_review posts"

    for item in body["items"]:
        assert "status" in item, f"status field missing on item {item.get('id')}"


async def test_different_user_sees_only_approved_post(
    async_client: AsyncClient,
    alice_user: dict,
    bob_user: dict,
    alice_posts: list,
) -> None:
    """Scenario 3 — authenticated as bob (not the author) → only approved post returned.

    Bob is a different authenticated user. He must receive the same public view
    as an unauthenticated caller: only alice's approved posts.
    """
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    _fastapi_app.dependency_overrides[get_optional_user] = lambda: bob_user
    try:
        response = await async_client.get(_ENDPOINT.format(username=_ALICE_USERNAME))
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]

    assert response.status_code == 200, response.text
    body = response.json()

    assert body["total_count"] == 1, (
        f"expected 1 approved post for a different authenticated user, got {body['total_count']}"
    )
    assert len(body["items"]) == 1
    assert body["items"][0]["status"] == "approved"
