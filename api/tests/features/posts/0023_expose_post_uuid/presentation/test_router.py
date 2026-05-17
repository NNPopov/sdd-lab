# FEATURE: expose_post_uuid — endpoint integration tests.
#
# Covers: F1 (GET /{username}/posts items contain post_uuid)
#         F2 (GET /posts items contain post_uuid)
#         F3 (POST /{username}/post response contains post_uuid)
#         F4 (GET /{username}/post/{id} response contains post_uuid)
#         F5 (all four post_uuid values are equal for the same post)
#         F9 (read_post serialises post_uuid; raw uuid field absent from JSON)
import uuid

import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_CREATE = "/api/v1/{username}/post"
_LIST = "/api/v1/{username}/posts"
_LIST_ALL = "/api/v1/posts"
_READ = "/api/v1/{username}/post/{id}"


def _valid_uuid(value: object) -> bool:
    if not isinstance(value, str):
        return False
    try:
        uuid.UUID(value)
        return True
    except ValueError:
        return False


async def test_all_four_endpoints_return_valid_and_consistent_post_uuid(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F1, F2, F3, F4, F5: post_uuid is a valid UUID and identical across all four endpoints."""
    from app.bootstrap.container import container as _di_container
    from app.features.users.dependencies import get_current_user, get_optional_user
    from app.main import app as _fastapi_app

    username = seeded_alice["username"]
    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    _fastapi_app.dependency_overrides[get_optional_user] = lambda: seeded_alice
    try:
        create_resp = await async_client.post(
            _CREATE.format(username=username),
            json={"title": "Router UUID Test", "text": "Checking post_uuid in responses."},
        )
        assert create_resp.status_code == 201, create_resp.text
        create_body = create_resp.json()
        assert "post_uuid" in create_body, f"post_uuid absent; keys: {sorted(create_body)}"
        assert _valid_uuid(create_body["post_uuid"]), f"invalid UUID: {create_body['post_uuid']!r}"
        post_id = create_body["id"]
        create_uuid = create_body["post_uuid"]

        async with _di_container.session_factory()() as session:
            await session.execute(
                text('UPDATE "post" SET status = :s WHERE id = :id'),
                {"s": "approved", "id": post_id},
            )
            await session.commit()

        list_resp = await async_client.get(_LIST.format(username=username))
        assert list_resp.status_code == 200, list_resp.text
        list_body = list_resp.json()
        assert list_body["total_count"] >= 1
        list_item = next(i for i in list_body["items"] if i["id"] == post_id)
        assert "post_uuid" in list_item, f"post_uuid absent in list_posts item; keys: {sorted(list_item)}"
        assert _valid_uuid(list_item["post_uuid"])
        list_uuid = list_item["post_uuid"]

        all_resp = await async_client.get(_LIST_ALL)
        assert all_resp.status_code == 200, all_resp.text
        all_body = all_resp.json()
        assert all_body["total_count"] >= 1
        all_item = next(i for i in all_body["items"] if i["id"] == post_id)
        assert "post_uuid" in all_item, f"post_uuid absent in list_all_posts item; keys: {sorted(all_item)}"
        assert _valid_uuid(all_item["post_uuid"])
        all_uuid = all_item["post_uuid"]

        read_resp = await async_client.get(_READ.format(username=username, id=post_id))
        assert read_resp.status_code == 200, read_resp.text
        read_body = read_resp.json()
        assert "post_uuid" in read_body, f"post_uuid absent in read_post response; keys: {sorted(read_body)}"
        assert _valid_uuid(read_body["post_uuid"])
        read_uuid = read_body["post_uuid"]

        assert create_uuid == list_uuid == all_uuid == read_uuid, (
            f"post_uuid mismatch: create={create_uuid!r}, list={list_uuid!r}, all={all_uuid!r}, read={read_uuid!r}"
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]
        del _fastapi_app.dependency_overrides[get_optional_user]


async def test_read_post_response_contains_post_uuid_not_raw_uuid(
    async_client: AsyncClient,
    seeded_alice: dict,
) -> None:
    """F4, F9: read_post JSON has post_uuid but not the raw ORM column name 'uuid'."""
    from app.features.users.dependencies import get_current_user
    from app.main import app as _fastapi_app

    username = seeded_alice["username"]
    _fastapi_app.dependency_overrides[get_current_user] = lambda: seeded_alice
    try:
        create_resp = await async_client.post(
            _CREATE.format(username=username),
            json={"title": "UUID Field Leak Check", "text": "Verifying uuid is excluded."},
        )
        assert create_resp.status_code == 201, create_resp.text
        post_id = create_resp.json()["id"]
    finally:
        del _fastapi_app.dependency_overrides[get_current_user]

    read_resp = await async_client.get(_READ.format(username=username, id=post_id))
    assert read_resp.status_code == 200, read_resp.text
    body = read_resp.json()

    assert "post_uuid" in body, f"post_uuid must be present; keys: {sorted(body)}"
    assert "uuid" not in body, f"raw ORM 'uuid' field must be absent; keys: {sorted(body)}"
    assert _valid_uuid(body["post_uuid"]), f"invalid UUID: {body['post_uuid']!r}"
