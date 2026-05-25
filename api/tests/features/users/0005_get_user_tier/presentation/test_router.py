# FEATURE: get_user_tier — endpoint integration tests.
#
# Covers: F1 (200 with tier body), F2 (200 null body), F3 (422 non-integer
#         user_id), F5/F8/F9 (404 User not found), F6/F8/F9 (404 Tier not found).
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import text

pytestmark = pytest.mark.asyncio

_ENDPOINT = "/api/v1/user/{user_id}/tier"


# ── F1: user with tier → 200 with all three fields ───────────────────────────


async def test_get_user_tier_returns_200_with_tier_body(
    async_client: AsyncClient,
    seeded_user_with_tier,
) -> None:
    tier, user = seeded_user_with_tier

    response = await async_client.get(_ENDPOINT.format(user_id=user.id))

    assert response.status_code == 200
    body = response.json()
    assert body is not None
    assert body["tier_id"] == tier.id
    assert body["tier_name"] == tier.name
    assert "tier_created_at" in body
    assert set(body.keys()) == {"tier_id", "tier_name", "tier_created_at"}


# ── F2: user found, no tier → 200 null ───────────────────────────────────────


async def test_get_user_tier_returns_200_null_when_no_tier(
    async_client: AsyncClient,
) -> None:
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="No Tier User",
            username="notieruser",
            email="notier@example.com",
            hashed_password="hashed_pw",
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        user_id = user.id

    response = await async_client.get(_ENDPOINT.format(user_id=user_id))

    assert response.status_code == 200
    assert response.json() is None


# ── F5/F8/F9: unknown user_id → 404 User not found ───────────────────────────


async def test_get_user_tier_returns_404_for_unknown_user(
    async_client: AsyncClient,
) -> None:
    response = await async_client.get(_ENDPOINT.format(user_id=999999))

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "User not found"


# ── F3: non-integer user_id → 422 ────────────────────────────────────────────


async def test_get_user_tier_returns_422_for_non_integer_user_id(
    async_client: AsyncClient,
) -> None:
    response = await async_client.get(_ENDPOINT.format(user_id="abc"))

    assert response.status_code == 422


# ── F6/F8/F9: user with dangling tier_id → 404 Tier not found ────────────────


@pytest_asyncio.fixture()
async def seeded_user_with_dangling_tier(async_client: AsyncClient) -> int:
    """Insert a user whose tier_id references a non-existent tier row.

    Achieved by inserting tier + user, then deleting the tier row.
    Requires deferred FK check or disabling constraints for the session.
    If the PostgreSQL FK is not deferrable this fixture is skipped.
    """
    from app.adapters.db.models.tier import Tier
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        tier = Tier(name="ghost_tier")
        session.add(tier)
        await session.flush()
        tier_id = tier.id

        user = User(
            name="Dangling User",
            username="danglinguser",
            email="dangling@example.com",
            hashed_password="hashed_pw",
        )
        user.tier_id = tier_id
        session.add(user)
        await session.flush()
        user_id = user.id

        # Delete the tier while deferring FK checks so the user row becomes orphaned.
        try:
            await session.execute(text("SET CONSTRAINTS ALL DEFERRED"))
            await session.execute(text("DELETE FROM tier WHERE id = :id").bindparams(id=tier_id))
            await session.commit()
        except Exception:
            pytest.skip("FK constraint is not deferrable; skipping dangling-tier scenario")

    return user_id


async def test_get_user_tier_returns_404_for_dangling_tier_id(
    async_client: AsyncClient,
    seeded_user_with_dangling_tier: int,
) -> None:
    user_id = seeded_user_with_dangling_tier

    response = await async_client.get(_ENDPOINT.format(user_id=user_id))

    assert response.status_code == 404
    body = response.json()
    assert body["error"]["code"] == "notfound"
    assert body["error"]["message"] == "Tier not found"
