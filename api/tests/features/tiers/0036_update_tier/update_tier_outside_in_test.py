# FEATURE: update_tier — outside-in acceptance test.
#
# Covers: F1, F9, F10, F11, F14, F15 (see specs/features/tiers/0039_update_tier_by_id/requirements.md).
#
# Red-state trigger: the implementation still uses PATCH /tier/{name} and the
# request body field new_name. Scenario 1 sends PATCH /tier/{id} (an integer),
# which the old route /tier/{name} does not match → 404 (or 405 if FastAPI
# tries to coerce) → status assertion fails immediately.
# Scenario 2 fails identically.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"


async def _seed_tier(name: str) -> int:
    """Insert a tier row and return its generated primary-key id."""
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW()) RETURNING id"),
            {"name": name},
        )
        await session.commit()
        return result.scalar_one()


async def test_update_tier_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — superuser renames a tier by id; response is 200 with confirmation, DB reflects the change."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    tier_id = await _seed_tier("silver")

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            f"{_ENDPOINT}/{tier_id}",
            json={"name": "platinum"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Tier updated"}

    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("SELECT name, updated_at FROM tier WHERE id = :id"),
            {"id": tier_id},
        )
        row = result.first()
        assert row is not None, f"tier with id={tier_id} not found after rename"
        assert row.name == "platinum"
        assert row.updated_at is not None, "updated_at must be set after rename"

        gone = await session.execute(
            text("SELECT id FROM tier WHERE name = :n"),
            {"n": "silver"},
        )
        assert gone.first() is None, "old tier name 'silver' still exists after rename"


async def test_update_tier_duplicate_name_returns_409(async_client: AsyncClient) -> None:
    """Scenario 2 — rename to a name already taken returns 409 via the full exception-handler chain."""
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    silver_id = await _seed_tier("silver")
    await _seed_tier("gold")

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            f"{_ENDPOINT}/{silver_id}",
            json={"name": "gold"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 409, response.text
    assert response.json() == {
        "error": {
            "code": "duplicatevalue",
            "message": "Tier name already exists",
        }
    }

    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        for name in ("silver", "gold"):
            result = await session.execute(
                text("SELECT name FROM tier WHERE name = :n"),
                {"n": name},
            )
            assert result.first() is not None, f"tier '{name}' missing after failed rename"
