# FEATURE: create_user — endpoint integration tests.
from unittest.mock import AsyncMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.domain.errors import DuplicateValueDomainError
from app.features.users.create_user.domain.entities import CreatedUser
from app.features.users.create_user.presentation.router import _get_create_user_use_case

_ENDPOINT = "/api/v1/user"

_VALID_PAYLOAD = {
    "name": "Alice Example",
    "username": "alice99",
    "email": "alice99@example.com",
    "password": "Str0ng!pw",
}

_ENTITY = CreatedUser(
    id=42,
    name="Alice Example",
    username="alice99",
    email="alice99@example.com",
    profile_image_url="https://profileimageurl.com",
    tier_id=None,
)


@pytest.fixture()
def mocked_use_case() -> AsyncMock:
    return AsyncMock(return_value=_ENTITY)


@pytest.fixture()
async def http_client(mocked_use_case: AsyncMock) -> AsyncClient:
    from app.main import app

    app.dependency_overrides[_get_create_user_use_case] = lambda: mocked_use_case
    try:
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client
    finally:
        app.dependency_overrides.pop(_get_create_user_use_case, None)


@pytest.mark.asyncio
async def test_valid_request_returns_201_with_response_shape(http_client: AsyncClient) -> None:
    response = await http_client.post(_ENDPOINT, json=_VALID_PAYLOAD)
    assert response.status_code == 201
    body = response.json()
    assert body["id"] == 42
    assert body["username"] == "alice99"
    assert body["email"] == "alice99@example.com"
    assert body["tier_id"] is None


@pytest.mark.asyncio
async def test_invalid_email_returns_422(http_client: AsyncClient) -> None:
    payload = {**_VALID_PAYLOAD, "email": "not-an-email"}
    response = await http_client.post(_ENDPOINT, json=payload)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_short_password_returns_422(http_client: AsyncClient) -> None:
    payload = {**_VALID_PAYLOAD, "password": "short"}
    response = await http_client.post(_ENDPOINT, json=payload)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_duplicate_value_error_returns_409(http_client: AsyncClient, mocked_use_case: AsyncMock) -> None:
    mocked_use_case.side_effect = DuplicateValueDomainError("Email is already registered")
    response = await http_client.post(_ENDPOINT, json=_VALID_PAYLOAD)
    assert response.status_code == 409
    assert response.json() == {"error": {"code": "duplicatevalue", "message": "Email is already registered"}}
