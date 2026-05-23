# FEATURE: update_tier — outside-in acceptance test.
#
# Covers: F1, F5, F8, F9, F10, F11, F14, F15 (see requirements.md).
#
# Red-state trigger: features/tiers/update_tier/ does not exist yet.
# PATCH /tier/{name} is handled by the old patch_tier handler which uses
# async_get_db and TierUpdate(name: str | None). Sending {"new_name": ...}
# means TierUpdate.name=None, so FastCRUD skips the update and the row is
# not renamed — Scenario 1 fails at the DB assertion ("platinum" not found).
# For Scenario 2 the old handler returns 200 (no IntegrityError because name
# is not updated), but the test expects 409 → assertion fails immediately.
import pytest
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/tier"


async def test_update_tier_happy_path(async_client: AsyncClient) -> None:
    """Scenario 1 — superuser renames a tier; response is 200 with confirmation, DB reflects the change."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    # Seed: insert 'silver' inside the test transaction.
    async with _di_container.session_factory()() as session:
        await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW())"),
            {"name": "silver"},
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            f"{_ENDPOINT}/silver",
            json={"new_name": "platinum"},
        )
    finally:
        del _fastapi_app.dependency_overrides[get_current_superuser]

    assert response.status_code == 200, response.text
    assert response.json() == {"message": "Tier updated"}

    # DB assertion: 'platinum' exists with a non-null updated_at; 'silver' is gone.
    async with _di_container.session_factory()() as session:
        result = await session.execute(
            text("SELECT name, updated_at FROM tier WHERE name = :n"),
            {"n": "platinum"},
        )
        row = result.first()
        assert row is not None, "renamed tier 'platinum' not found in test transaction after rename"
        assert row.name == "platinum"
        assert row.updated_at is not None, "updated_at must be set after rename"

        gone = await session.execute(
            text("SELECT id FROM tier WHERE name = :n"),
            {"n": "silver"},
        )
        assert gone.first() is None, "old tier name 'silver' still exists after rename"


async def test_update_tier_duplicate_name_returns_409(async_client: AsyncClient) -> None:
    """Scenario 2 — rename to a name already taken returns 409 via the full exception-handler chain."""
    from app.bootstrap.container import container as _di_container
    from app.main import app as _fastapi_app
    from app.shared_dependencies import get_current_superuser

    # Seed: insert 'silver' and 'gold' inside the test transaction.
    async with _di_container.session_factory()() as session:
        await session.execute(
            text("INSERT INTO tier (name, created_at) VALUES (:name, NOW())"),
            [{"name": "silver"}, {"name": "gold"}],
        )
        await session.commit()

    _fastapi_app.dependency_overrides[get_current_superuser] = lambda: None
    try:
        response = await async_client.patch(
            f"{_ENDPOINT}/silver",
            json={"new_name": "gold"},
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

    # DB assertion: both rows are unchanged after the failed rename.
    async with _di_container.session_factory()() as session:
        for name in ("silver", "gold"):
            result = await session.execute(
                text("SELECT name FROM tier WHERE name = :n"),
                {"n": name},
            )
            assert result.first() is not None, f"tier '{name}' missing after failed rename"
