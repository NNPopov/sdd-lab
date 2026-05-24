# FEATURE: get_user_by_id — endpoint integration tests.
import pytest
from httpx import AsyncClient

_ENDPOINT = "/api/v1/user/{user_id}"

_CREATE_PAYLOAD = {
    "username": "routertester",
    "name": "Router Tester",
    "email": "routertester@example.com",
    "password": "Pa$$w0rd1",
}


@pytest.mark.asyncio
async def test_get_existing_user_returns_200_with_all_fields(async_client: AsyncClient) -> None:
    create_resp = await async_client.post("/api/v1/user", json=_CREATE_PAYLOAD)
    assert create_resp.status_code == 201
    user_id = create_resp.json()["id"]

    response = await async_client.get(_ENDPOINT.format(user_id=user_id))

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == user_id
    assert body["username"] == "routertester"
    assert body["name"] == "Router Tester"
    assert body["email"] == "routertester@example.com"
    assert isinstance(body["profile_image_url"], str)
    assert body["tier_id"] is None
    assert body["is_moderator"] is False
    assert set(body.keys()) == {"id", "name", "username", "email", "profile_image_url", "tier_id", "is_moderator"}


@pytest.mark.asyncio
async def test_get_nonexistent_user_returns_404(async_client: AsyncClient) -> None:
    response = await async_client.get(_ENDPOINT.format(user_id=999_999))
    assert response.status_code == 404
    assert response.json() == {"error": {"code": "notfound", "message": "User not found"}}


@pytest.mark.asyncio
async def test_non_integer_path_returns_422(async_client: AsyncClient) -> None:
    response = await async_client.get("/api/v1/user/not-an-int")
    assert response.status_code == 422
