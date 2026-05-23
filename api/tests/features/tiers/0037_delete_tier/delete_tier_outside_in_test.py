# FEATURE: delete_tier — outside-in acceptance test.
#
# Covers: F1, F3, F7, F8 (Scenario 1); F2, F4 (Scenario 2).
#
# Red-state note: this is a fat-handler migration slice. The old erase_tier
# handler in tiers/router.py already returns {"message": "Tier deleted"} and
# raises NotFoundDomainError("Tier not found") — the same responses the new
# DeleteTierUseCase will produce. Because the conftest overrides async_get_db
# (routing the old handler through the test transaction), both scenarios may
# pass against the old handler.
#
# The genuine red signal appears only if the old handler is removed before the
# new one is wired in — at that point DELETE /api/v1/tier/{name} returns 405.
# Implementors: remove erase_tier and add the new sub-router atomically so the
# test never sees 405 in the green phase.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"


async def test_delete_tier_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — superuser deletes an existing tier; 200 with confirmation, DB row gone."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    async with _di_container.session_factory()() as session:
        await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW())"),
            {"name": "silver"},
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(f"{_ENDPOINT}/silver")
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Tier deleted"}

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("SELECT id FROM tier WHERE name = :n"),
            {"n": "silver"},
        )
        assert result.first() is None, "tier 'silver' still exists after deletion"


async def test_delete_tier_not_found(async_client: AsyncClient) -> None:
    """Scenario 2 — tier does not exist; 404 with domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(f"{_ENDPOINT}/nonexistent")
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 404, response.text
    assert response.json() == {
        "error": {
            "code": "notfound",
            "message": "Tier not found",
        }
    }
