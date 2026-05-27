# FEATURE: extract_user_lookup — UserLookupAdapter unit tests (real test Postgres).
#
# Covers: get_active_user_by_id behaviour (0055 F16) and N3 (OperationalError propagation).
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


# ── N3: infrastructure exception propagates unchanged ────────────────────────


async def test_get_active_user_by_id_propagates_operational_error() -> None:
    """N3 — OperationalError from session.execute is not caught; propagates to caller."""
    mock_session = AsyncMock()
    mock_session.execute.side_effect = OperationalError("simulated connection failure", None, None)

    mock_cm = AsyncMock()
    mock_cm.__aenter__ = AsyncMock(return_value=mock_session)
    mock_cm.__aexit__ = AsyncMock(return_value=False)

    mock_factory = MagicMock(return_value=mock_cm)

    adapter = UserLookupAdapter(session_factory=mock_factory)

    with pytest.raises(OperationalError):
        await adapter.get_active_user_by_id(123)


# ── 0055 F16: get_active_user_by_id — active user found → UserIdentity ────────


async def test_get_active_user_by_id_returns_user_identity_for_active_user(
    el32_alice: dict,
) -> None:
    """0055 F16 — existing active user resolved by id → UserIdentity with matching fields."""
    adapter = _make_adapter()
    result = await adapter.get_active_user_by_id(el32_alice["id"])
    assert isinstance(result, UserIdentity)
    assert result.id == el32_alice["id"]
    assert result.username == "el32alice"


# ── 0055 F16: unknown id → None ──────────────────────────────────────────────


async def test_get_active_user_by_id_returns_none_for_unknown_id(
    async_client: AsyncClient,
) -> None:
    """0055 F16 — no row with that id → None."""
    adapter = _make_adapter()
    result = await adapter.get_active_user_by_id(999999999)
    assert result is None


# ── 0055 F16: soft-deleted user → None ───────────────────────────────────────


async def test_get_active_user_by_id_returns_none_for_soft_deleted_user(
    async_client: AsyncClient,
) -> None:
    """0055 F16 — user exists but is_deleted=True → None (filter excludes soft-deleted rows)."""
    from app.adapters.db.models.user import User
    from app.bootstrap.container import container as _di_container

    async with _di_container.session_factory()() as session:
        user = User(
            name="EL32 Deleted By Id",
            username="el32deleted_byid_xyz",
            email="el32deleted_byid_xyz@example.com",
            hashed_password="fake",
            is_deleted=True,
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        deleted_id = user.id

    adapter = _make_adapter()
    result = await adapter.get_active_user_by_id(deleted_id)
    assert result is None
