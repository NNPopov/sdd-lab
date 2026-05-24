# FEATURE: delete_tier — endpoint integration tests.
#
# Covers: F1, F6, F7, F8.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier/{id}"


# ── F1: happy path → 200 ──────────────────────────────────────────────────────


async def test_delete_tier_returns_200_on_success(async_client: AsyncClient) -> None:
    """F1 — superuser + existing tier → 200 with confirmation message."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": "router_del_silver"},
        )
        tier_id = result.scalar_one()
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(_ENDPOINT.format(id=tier_id))
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200
    assert response.json() == {"message": "Tier deleted"}


# ── F6: not found → 404 ───────────────────────────────────────────────────────


async def test_delete_tier_returns_404_for_unknown_id(async_client: AsyncClient) -> None:
    """F6 — path id does not match any tier → 404."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(_ENDPOINT.format(id=999999999))
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "Tier not found"


# ── F2: non-integer id → 422 ─────────────────────────────────────────────────


async def test_delete_tier_returns_422_for_non_integer_id(async_client: AsyncClient) -> None:
    """F2 — non-integer path segment → FastAPI returns 422 before reaching use-case."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete("/api/v1/tier/not-an-int")
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 422


# ── F7: non-superuser → 403 ───────────────────────────────────────────────────


async def test_delete_tier_non_superuser_returns_403(async_client: AsyncClient) -> None:
    """F7 — authenticated non-superuser → 403."""
    from fastcrud.exceptions.http_exceptions import ForbiddenException

    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    def _raise_forbidden() -> None:
        raise ForbiddenException()

    _fastapi_app.dependency_overrides[get_current_superuser] = _raise_forbidden
    try:
        response = await async_client.delete(_ENDPOINT.format(id=1))
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 403


# ── F8: unauthenticated → 401 ─────────────────────────────────────────────────


async def test_delete_tier_unauthenticated_returns_401(async_client: AsyncClient) -> None:
    """F8 — no bearer token → 401."""
    response = await async_client.delete(_ENDPOINT.format(id=1))
    assert response.status_code == 401
