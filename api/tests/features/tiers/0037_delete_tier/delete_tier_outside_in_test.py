# FEATURE: delete_tier — outside-in acceptance test.
#
# Covers: F1, F3, F5, F9, F10 (Scenario 1); F4, F6 (Scenario 2).
#
# Red-state note (slice 0040): the implementation still routes DELETE /tier/{name}
# (string parameter). When this test calls DELETE /tier/{tier_id} (an integer),
# the old adapter looks up Tier.name == str(tier_id) and finds no row, returning
# 404. Scenario 1 therefore fails (expected 200, got 404) — the red signal.
# Scenario 2 passes in the red state because the old handler also returns 404
# for any name that does not exist in the table.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"


async def test_delete_tier_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — superuser deletes an existing tier by id; 200 with confirmation, DB row gone."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": "silver"},
        )
        tier_id = result.scalar_one()
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(f"{_ENDPOINT}/{tier_id}")
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Tier deleted"}

    async with _di_container.session_factory()() as session:
        check = await session.execute(
            text("SELECT id FROM tier WHERE id = :id"),
            {"id": tier_id},
        )
        assert check.first() is None, f"tier id={tier_id} still exists after deletion"


async def test_delete_tier_not_found(async_client: AsyncClient) -> None:
    """Scenario 2 — no tier with given id exists; 404 with domain error body."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.delete(f"{_ENDPOINT}/999999")
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 404, response.text
    assert response.json() == {
        "error": {
            "code": "notfound",
            "message": "Tier not found",
        }
    }
