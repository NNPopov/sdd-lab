# FEATURE: extract_user_lookup — UserLookupAdapter unit tests (real test Postgres).
#
# Covers: F5, F6, F7, F8, N3.
#
# Outside-in test opted out for this slice (pure refactor, no new HTTP entry point).
# Acceptance gate: the four existing outside-in tests for create_post, update_post,
# erase_post, and erase_db_post remain green. See tests.md.
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import AsyncClient
from sqlalchemy.exc import OperationalError

from app.features.posts._shared.entities import UserIdentity
from app.features.posts._shared.user_lookup_adapter import UserLookupAdapter

pytestmark = pytest.mark.asyncio


def _make_adapter() -> UserLookupAdapter:
    from app.bootstrap.container import container as _di_container

    return UserLookupAdapter(session_factory=_di_container.session_factory())


# ── F5, F6: active user found → UserIdentity ─────────────────────────────────


async def test_get_active_user_by_username_returns_user_identity_for_active_user(
    el32_alice: dict,
) -> None:
    """F5, F6 — existing active user → UserIdentity with correct id and username."""
    adapter = _make_adapter()
    result = await adapter.get_active_user_by_username("el32alice")
    assert isinstance(result, UserIdentity)
    assert result.username == "el32alice"
    assert result.id == el32_alice["id"]


# ── F7: non-existent username → None ─────────────────────────────────────────


async def test_get_active_user_by_username_returns_none_for_unknown_username(
    async_client: AsyncClient,
) -> None:
    """F7 — no matching row → None."""
    adapter = _make_adapter()
    result = await adapter.get_active_user_by_username("no_such_el32_user_xyz")
    assert result is None


# ── F8: soft-deleted user → None ─────────────────────────────────────────────


async def test_get_active_user_by_username_returns_none_for_soft_deleted_user(
    async_client: AsyncClient,
) -> None:
    """F8 — user exists but is_deleted=True → None (filter excludes soft-deleted rows)."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EL32 Deleted",
            username="el32deleted_xyz",
            email="el32deleted_xyz@example.com",
            hashed_password="fake",
            is_deleted=True,
        )
        session.add(user)
        await session.commit()

    adapter = _make_adapter()
    result = await adapter.get_active_user_by_username("el32deleted_xyz")
    assert result is None


# ── N3: infrastructure exception propagates unchanged ────────────────────────


async def test_get_active_user_by_username_propagates_operational_error() -> None:
    """N3 — OperationalError from session.execute is not caught; propagates to caller."""
    mock_session = AsyncMock()
    mock_session.execute.side_effect = OperationalError("simulated connection failure", None, None)

    mock_cm = AsyncMock()
    mock_cm.__aenter__ = AsyncMock(return_value=mock_session)
    mock_cm.__aexit__ = AsyncMock(return_value=False)

    mock_factory = MagicMock(return_value=mock_cm)

    adapter = UserLookupAdapter(session_factory=mock_factory)

    with pytest.raises(OperationalError):
        await adapter.get_active_user_by_username("alice")
