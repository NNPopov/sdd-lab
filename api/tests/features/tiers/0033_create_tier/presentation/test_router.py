# FEATURE: create_tier — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F5.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"


# ── F1, F8, F10: happy path → 201 ────────────────────────────────────────────


async def test_create_tier_returns_201_with_correct_schema(async_client: AsyncClient) -> None:
    """F1 — valid payload + superuser → 201; response matches CreateTierResponse schema."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.post(_ENDPOINT, json={"name": "silver"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 201
    body = response.json()
    assert body["name"] == "silver"
    assert isinstance(body["id"], int) and body["id"] > 0
    assert "created_at" in body


# ── F5: duplicate name → 409 ─────────────────────────────────────────────────


async def test_create_tier_duplicate_returns_409(async_client: AsyncClient) -> None:
    """F5 — duplicate name → DuplicateValueDomainError → 409."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        first = await async_client.post(_ENDPOINT, json={"name": "bronze"})
        assert first.status_code == 201
        second = await async_client.post(_ENDPOINT, json={"name": "bronze"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert second.status_code == 409
    assert second.json()["error"]["code"] == "duplicatevalue"


# ── F2: no token → 401 ───────────────────────────────────────────────────────


async def test_create_tier_unauthenticated_returns_401(async_client: AsyncClient) -> None:
    """F2 — no bearer token → 401."""
    response = await async_client.post(_ENDPOINT, json={"name": "copper"})
    assert response.status_code == 401


# ── F3: non-superuser → 403 ──────────────────────────────────────────────────


async def test_create_tier_non_superuser_returns_403(async_client: AsyncClient) -> None:
    """F3 — authenticated non-superuser → 403."""
    from fastcrud.exceptions.http_exceptions import ForbiddenException

    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    def _raise_forbidden() -> None:
        raise ForbiddenException()

    _fastapi_app.dependency_overrides[get_current_superuser] = _raise_forbidden
    try:
        response = await async_client.post(_ENDPOINT, json={"name": "copper"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 403


# ── F4: missing name → 422 ───────────────────────────────────────────────────


async def test_create_tier_missing_name_returns_422(async_client: AsyncClient) -> None:
    """F4 — missing name field → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.post(_ENDPOINT, json={})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 422


async def test_create_tier_empty_name_returns_422(async_client: AsyncClient) -> None:
    """F4 — empty string name violates min_length=1 → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.post(_ENDPOINT, json={"name": ""})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 422
