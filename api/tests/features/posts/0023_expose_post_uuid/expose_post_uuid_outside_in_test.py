# FEATURE: expose_post_uuid — outside-in acceptance test.
#
# Covers: F1 (scenario 1 — list_posts items carry post_uuid)
#         F2 (scenario 1 — list_all_posts items carry post_uuid)
#         F3 (scenario 1 — create_post response carries post_uuid)
#         F4 (scenarios 1 and 2 — read_post response carries post_uuid)
#         F5 (scenario 1 — all four post_uuid values are equal)
#         F9 (scenario 2 — read_post serialises post_uuid, not the raw ORM uuid field)
#
# Red-state trigger: PostItem, CreatedPost, and PostRead do not yet carry
# post_uuid. The assertion "post_uuid" in create_body fails immediately in
# scenario 1 because CreatePostResponse does not include the field.
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_CREATE_POST_PATH = "/api/v1/{username}/post"
_LIST_POSTS_PATH = "/api/v1/{username}/posts"
_LIST_ALL_POSTS_PATH = "/api/v1/posts"
_READ_POST_PATH = "/api/v1/{username}/post/{id}"


async def test_post_uuid_present_and_consistent(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 1 — post_uuid present in create, list_posts, list_all_posts, and read_post.

    Creates one post as alice, approves it, then calls all four affected endpoints
    and asserts that post_uuid is a valid UUID and is identical across all four responses.
    """
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user, get_optional_user
    from app.main import app as _fastapi_app

    username = seeded_alice["username"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    _fastapi_app.dependency_overrides[get_optional_user] = lambda: seeded_alice
    try:
        # 1. Create post via HTTP — verifies F3.
        create_resp = await async_client.post(
            _CREATE_POST_PATH.format(username=username),
            json={"title": "UUID Test Post", "text": "Checking post_uuid propagation."},
        )
        assert create_resp.status_code == 201, create_resp.text
        create_body = create_resp.json()
        assert "post_uuid" in create_body, (
            f"post_uuid missing from create_post response; keys present: {sorted(create_body.keys())}"
        )
        create_post_uuid = create_body["post_uuid"]
        assert _is_valid_uuid(create_post_uuid), f"create_post: post_uuid is not a valid UUID: {create_post_uuid!r}"
        post_id = create_body["id"]

        # 2. Approve the post so it appears in the public global feed.
        async with _di_container.session_factory()() as session:
            await session.execute(
                text('UPDATE "post" SET status = :status WHERE id = :id'),
                {"status": "approved", "id": post_id},
            )
            await session.commit()

        # 3. GET /api/v1/{username}/posts — verifies F1.
        list_posts_resp = await async_client.get(_LIST_POSTS_PATH.format(username=username))
        assert list_posts_resp.status_code == 200, list_posts_resp.text
        list_posts_body = list_posts_resp.json()
        assert list_posts_body["total_count"] >= 1
        list_item = list_posts_body["items"][0]
        assert "post_uuid" in list_item, f"post_uuid missing from list_posts item; keys: {sorted(list_item.keys())}"
        list_posts_uuid = list_item["post_uuid"]
        assert _is_valid_uuid(list_posts_uuid), f"list_posts: post_uuid is not a valid UUID: {list_posts_uuid!r}"

        # 4. GET /api/v1/posts — alice is a regular user (not privileged), post is
        #    approved, so it appears in the public view — verifies F2.
        list_all_resp = await async_client.get(_LIST_ALL_POSTS_PATH)
        assert list_all_resp.status_code == 200, list_all_resp.text
        list_all_body = list_all_resp.json()
        assert list_all_body["total_count"] >= 1
        all_item = list_all_body["items"][0]
        assert "post_uuid" in all_item, f"post_uuid missing from list_all_posts item; keys: {sorted(all_item.keys())}"
        list_all_uuid = all_item["post_uuid"]
        assert _is_valid_uuid(list_all_uuid), f"list_all_posts: post_uuid is not a valid UUID: {list_all_uuid!r}"

        # 5. GET /api/v1/{username}/post/{id} — verifies F4.
        read_resp = await async_client.get(_READ_POST_PATH.format(username=username, id=post_id))
        assert read_resp.status_code == 200, read_resp.text
        read_body = read_resp.json()
        assert "post_uuid" in read_body, f"post_uuid missing from read_post response; keys: {sorted(read_body.keys())}"
        read_uuid = read_body["post_uuid"]
        assert _is_valid_uuid(read_uuid), f"read_post: post_uuid is not a valid UUID: {read_uuid!r}"

        # 6. All four post_uuid values must be equal — verifies F5.
        assert create_post_uuid == list_posts_uuid == list_all_uuid == read_uuid, (
            f"post_uuid mismatch across endpoints — "
            f"create={create_post_uuid!r}, list_posts={list_posts_uuid!r}, "
            f"list_all={list_all_uuid!r}, read={read_uuid!r}"
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]
        del _fastapi_app.dependency_overrides[get_optional_user]


async def test_read_post_exposes_post_uuid_not_raw_uuid_field(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """Scenario 2 — read_post JSON contains post_uuid but not a top-level uuid key.

    PostRead uses Field(exclude=True) on the ORM-mapped uuid field and exposes it
    via a computed_field named post_uuid. This test verifies the ORM column name
    does not leak into the serialised response.
    """
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    username = seeded_alice["username"]

    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        create_resp = await async_client.post(
            _CREATE_POST_PATH.format(username=username),
            json={"title": "UUID Field Leak Test", "text": "Verifying uuid is excluded from output."},
        )
        assert create_resp.status_code == 201, create_resp.text
        post_id = create_resp.json()["id"]
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    read_resp = await async_client.get(_READ_POST_PATH.format(username=username, id=post_id))
    assert read_resp.status_code == 200, read_resp.text
    body = read_resp.json()

    assert "post_uuid" in body, f"post_uuid must be present in read_post response; keys: {sorted(body.keys())}"
    assert "uuid" not in body, f"ORM field 'uuid' must not appear in read_post response; keys: {sorted(body.keys())}"
    assert _is_valid_uuid(body["post_uuid"]), f"post_uuid is not a valid UUID: {body['post_uuid']!r}"


def _is_valid_uuid(value: object) -> bool:
    """Return True if value is a non-empty string that parses as a valid UUID."""
    if not isinstance(value, str):
        return False
    try:
        uuid.UUID(value)
        return True
    except ValueError:
        return False
