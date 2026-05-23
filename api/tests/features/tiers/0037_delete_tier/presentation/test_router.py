# FEATURE: delete_tier — endpoint integration tests.
#
# Covers: F1, F4, F5, F6.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier/{name}"


# ── F1: happy path → 200 ──────────────────────────────────────────────────────


async def test_delete_tier_returns_200_on_success(async_client: AsyncClient) -> None:
    """F1 — superuser + existing tier → 200 with confirmation message."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    async with _di_container.session_factory()() as session:
        await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW())"),
            {"name": "router_del_silver"},
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(_ENDPOINT.format(name="router_del_silver"))
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200
    assert response.json() == {"message": "Tier deleted"}


# ── F4: not found → 404 ───────────────────────────────────────────────────────


async def test_delete_tier_returns_404_for_unknown_name(async_client: AsyncClient) -> None:
    """F4 — path name does not match any tier → 404."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(_ENDPOINT.format(name="nonexistent_xyz_99"))
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "Tier not found"


# ── F5: non-superuser → 403 ───────────────────────────────────────────────────


async def test_delete_tier_non_superuser_returns_403(async_client: AsyncClient) -> None:
    """F5 — authenticated non-superuser → 403."""
    from fastcrud.exceptions.http_exceptions import ForbiddenException

    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    def _raise_forbidden() -> None:
        raise ForbiddenException()

    _fastapi_app.dependency_overrides[get_current_superuser] = _raise_forbidden
    try:
        response = await async_client.delete(_ENDPOINT.format(name="any"))
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 403


# ── F6: unauthenticated → 401 ─────────────────────────────────────────────────


async def test_delete_tier_unauthenticated_returns_401(async_client: AsyncClient) -> None:
    """F6 — no bearer token → 401."""
    response = await async_client.delete(_ENDPOINT.format(name="any"))
    assert response.status_code == 401
