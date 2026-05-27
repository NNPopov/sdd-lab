# FEATURE: get_post — outside-in acceptance test.
#
# Covers: F1  (scenario 2 — approved post → HTTP 200, unauthenticated)
#         F2  (scenario 1 — author bypass, pending_review → HTTP 200)
#         F3  (scenario 1 — moderator bypass, pending_review → HTTP 200)
#         F4  (scenario 1 — neither author nor privileged → HTTP 404)
#         F5  (scenarios 1, 2 — port None → HTTP 404)
#         F6  (scenario 2 — unknown username / unknown post id → HTTP 404)
#         F7  (scenario 1 — pending, unauthenticated → HTTP 404)
#         F8  (scenario 1 — pending, other user → HTTP 404)
#         F9  (scenario 1 — pending, author → HTTP 200)
#         F10 (scenario 1 — pending, moderator → HTTP 200)
#         F13 (scenario 2 — response body includes username, status, post_uuid)
#         F15 (scenario 1/2 — PostItem returned with username and post_uuid)
#         F16 (scenario 2 — None returned for missing user/post → HTTP 404)
#         F17 (scenario 1 — adapter returns pending post with no status filter)
#
# Red-state trigger: the existing flat read_post function returns the post
# regardless of status. Scenario 1 step 1 (unauthenticated, pending_review)
# receives HTTP 200 but expects HTTP 404 → AssertionError.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_READ_POST_PATH = "/api/v1/{user_id}/post/{id}"


async def test_access_control_pending_post(
    async_client: AsyncClient,
    gp26_alice: dict,
    gp26_bob: dict,
    gp26_carol: dict,
    gp26_pending_post: dict,
) -> None:
    """Scenario 1 — Access control matrix for a pending_review post.

    A pending post is hidden (404) from unauthenticated callers and
    non-author non-privileged callers, but visible (200) to the author
    and to a moderator.
    """
    from app.features.users.dependencies import get_optional_user
    from app.main import app as _fastapi_app

    url = _READ_POST_PATH.format(
        user_id=gp26_alice["id"],
        id=gp26_pending_post["id"],
    )

    # Step 1 — unauthenticated caller → 404.
    response = await async_client.get(url)
    assert response.status_code == 404, (
        f"expected 404 (unauthenticated, pending_review), got {response.status_code}: {response.text}"
    )
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}

    # Step 2 — authenticated as bob (non-author, non-privileged) → 404.
    _fastapi_app.dependency_overrides[get_optional_user] = lambda: gp26_bob
    try:
        response = await async_client.get(url)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]
    assert response.status_code == 404, (
        f"expected 404 (bob, pending_review), got {response.status_code}: {response.text}"
    )
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}

    # Step 3 — authenticated as alice (the author) → 200.
    _fastapi_app.dependency_overrides[get_optional_user] = lambda: gp26_alice
    try:
        response = await async_client.get(url)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]
    assert response.status_code == 200, (
        f"expected 200 (author, pending_review), got {response.status_code}: {response.text}"
    )
    body = response.json()
    assert body["status"] == "pending_review"
    assert body["username"] == gp26_alice["username"]
    assert body["id"] == gp26_pending_post["id"]
    assert "post_uuid" in body, f"post_uuid missing from response; keys: {sorted(body.keys())}"

    # Step 4 — authenticated as carol (moderator) → 200.
    _fastapi_app.dependency_overrides[get_optional_user] = lambda: gp26_carol
    try:
        response = await async_client.get(url)
    finally:
        del _fastapi_app.dependency_overrides[get_optional_user]
    assert response.status_code == 200, (
        f"expected 200 (moderator, pending_review), got {response.status_code}: {response.text}"
    )
    assert response.json()["status"] == "pending_review"


async def test_approved_post_visibility_and_not_found(
    async_client: AsyncClient,
    gp26_alice: dict,
    gp26_pending_post: dict,
) -> None:
    """Scenario 2 — Approved post is publicly visible; missing paths return 404.

    Directly promotes the post to 'approved' in the DB, then verifies that
    an unauthenticated caller receives the full GetPostResponse. Also verifies
    that unknown username and unknown post id return 404.
    """
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container

    # Promote the post to approved via a direct DB update.
    async with _di_container.session_factory()() as session:
        await session.execute(
            text('UPDATE "post" SET status = :status WHERE id = :id'),
            {"status": "approved", "id": gp26_pending_post["id"]},
        )
        await session.commit()

    url = _READ_POST_PATH.format(
        user_id=gp26_alice["id"],
        id=gp26_pending_post["id"],
    )

    # Step 1 — approved post, unauthenticated → 200 with full response shape.
    response = await async_client.get(url)
    assert response.status_code == 200, (
        f"expected 200 (approved, unauthenticated), got {response.status_code}: {response.text}"
    )
    body = response.json()
    assert body["status"] == "approved"
    assert body["username"] == gp26_alice["username"]
    assert body["id"] == gp26_pending_post["id"]
    assert "post_uuid" in body, f"post_uuid missing; keys: {sorted(body.keys())}"
    assert "title" in body
    assert "text" in body

    # Step 2 — unknown user_id → 404 (no distinct "user not found").
    response = await async_client.get(_READ_POST_PATH.format(user_id=999999, id=gp26_pending_post["id"]))
    assert response.status_code == 404, f"expected 404 (unknown user_id), got {response.status_code}: {response.text}"
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}

    # Step 3 — unknown post id → 404.
    response = await async_client.get(_READ_POST_PATH.format(user_id=gp26_alice["id"], id=99999))
    assert response.status_code == 404, f"expected 404 (unknown post id), got {response.status_code}: {response.text}"
    assert response.json() == {"error": {"code": "notfound", "message": "Post not found"}}
