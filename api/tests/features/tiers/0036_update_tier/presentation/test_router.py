# FEATURE: update_tier — endpoint integration tests.
#
# Covers: F1, F2, F3, F4, F7, F11.
import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier/{id}"


# ── F1: happy path → 200 ─────────────────────────────────────────────────────


async def test_update_tier_returns_200_on_success(async_client: AsyncClient) -> None:
    """F1 — valid payload + superuser → 200 with confirmation message."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": "router_silver"},
        )
        await session.commit()
        tier_id = result.scalar_one()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            _ENDPOINT.format(id=tier_id),
            json={"name": "router_gold"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200
    assert response.json() == {"message": "Tier updated"}


# ── F7: not found → 404 ───────────────────────────────────────────────────────


async def test_update_tier_returns_404_for_unknown_id(async_client: AsyncClient) -> None:
    """F7 — path id does not match any tier → 404."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            _ENDPOINT.format(id=99999),
            json={"name": "anything"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "Tier not found"


# ── F11: duplicate name → 409 ────────────────────────────────────────────────


async def test_update_tier_returns_409_when_name_taken(async_client: AsyncClient) -> None:
    """F11 — name already taken → DuplicateValueDomainError → 409."""
    from sqlalchemy import text

    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": "router_dup_silver"},
        )
        silver_id = result.scalar_one()
        await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW())"),
            {"name": "router_dup_gold"},
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            _ENDPOINT.format(id=silver_id),
            json={"name": "router_dup_gold"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "duplicatevalue"


# ── F3: non-superuser → 403 ──────────────────────────────────────────────────


async def test_update_tier_non_superuser_returns_403(async_client: AsyncClient) -> None:
    """F3 — authenticated non-superuser → 403."""
    from fastcrud.exceptions.http_exceptions import ForbiddenException

    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    def _raise_forbidden() -> None:
        raise ForbiddenException()

    _fastapi_app.dependency_overrides[get_current_superuser] = _raise_forbidden
    try:
        response = await async_client.patch(
            _ENDPOINT.format(id=1),
            json={"name": "any2"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 403


# ── F3: unauthenticated → 401 ─────────────────────────────────────────────────


async def test_update_tier_unauthenticated_returns_401(async_client: AsyncClient) -> None:
    """F3 — no bearer token → 401."""
    response = await async_client.patch(
        _ENDPOINT.format(id=1),
        json={"name": "any2"},
    )
    assert response.status_code == 401


# ── F2: missing name → 422 ───────────────────────────────────────────────────


async def test_update_tier_missing_name_returns_422(async_client: AsyncClient) -> None:
    """F2 — missing name field → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(_ENDPOINT.format(id=1), json={})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 422


async def test_update_tier_empty_name_returns_422(async_client: AsyncClient) -> None:
    """F2 — empty name violates min_length=1 → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(_ENDPOINT.format(id=1), json={"name": ""})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 422


# ── F4: non-integer id → 422 ─────────────────────────────────────────────────


async def test_update_tier_non_integer_id_returns_422(async_client: AsyncClient) -> None:
    """F4 — non-integer path segment → 422."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch("/api/v1/tier/not-a-number", json={"name": "any"})
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 422
