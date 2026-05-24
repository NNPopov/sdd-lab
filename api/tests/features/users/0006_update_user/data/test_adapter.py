# FEATURE: update_user — adapter unit tests.
#
# Covers: F16–F22.
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from sqlalchemy.exc import IntegrityError

from app.domain.errors import DuplicateValueDomainError
from app.features.users.update_user.data.adapter import UpdateUserAdapter
from app.features.users.update_user.domain.commands import UpdateUserCommand
from app.features.users.update_user.domain.entities import ExistingUser

_UPDATE_CMD = UpdateUserCommand(
    target_user_id=1,
    requester_user_id=1,
    name="Alice Updated",
    email=None,
    username=None,
    profile_image_url=None,
)


def _make_adapter(session_mock: MagicMock) -> UpdateUserAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return UpdateUserAdapter(session_factory=factory)


# ── get_by_id ─────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_by_id_returns_existing_user_when_found() -> None:
    """F16 — active row found → ExistingUser returned."""
    from app.adapters.db.models.user import User

    row = MagicMock(spec=User)
    row.id = 42
    row.username = "alice"
    row.email = "alice@example.com"

    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = row
    session.execute = AsyncMock(return_value=result)

    adapter = _make_adapter(session)
    user = await adapter.get_by_id(1)

    assert isinstance(user, ExistingUser)
    assert user.id == 42
    assert user.username == "alice"
    assert user.email == "alice@example.com"


@pytest.mark.asyncio
async def test_get_by_id_returns_none_when_not_found() -> None:
    """F17 — no matching row → None."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)

    adapter = _make_adapter(session)
    assert await adapter.get_by_id(999) is None


# ── email_exists ──────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_email_exists_returns_true_when_row_found() -> None:
    """F18a — row present → True."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = object()
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).email_exists("taken@example.com") is True


@pytest.mark.asyncio
async def test_email_exists_returns_false_when_no_row() -> None:
    """F18b — no row → False."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).email_exists("free@example.com") is False


# ── username_exists ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_username_exists_returns_true_when_row_found() -> None:
    """F19a — row present → True."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = object()
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).username_exists("taken") is True


@pytest.mark.asyncio
async def test_username_exists_returns_false_when_no_row() -> None:
    """F19b — no row → False."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).username_exists("free") is False


# ── update ────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_update_integrity_error_maps_to_duplicate_value() -> None:
    """F20 — IntegrityError on commit → DuplicateValueDomainError."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=IntegrityError("dup", {}, None))

    adapter = _make_adapter(session)
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await adapter.update(_UPDATE_CMD)
    assert exc_info.value.message == "Email or username already taken"


@pytest.mark.asyncio
async def test_update_propagates_non_integrity_error() -> None:
    """N2 — non-IntegrityError propagates unchanged."""
    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock(side_effect=RuntimeError("unexpected"))

    adapter = _make_adapter(session)
    with pytest.raises(RuntimeError, match="unexpected"):
        await adapter.update(_UPDATE_CMD)


@pytest.mark.asyncio
async def test_update_sets_updated_at_in_payload() -> None:
    """F21 — updated_at set to current UTC time."""
    captured: dict = {}

    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock()

    before = datetime.now(UTC)

    adapter = _make_adapter(session)

    import app.features.users.update_user.data.adapter as adapter_module

    original_update = adapter_module.update

    def capturing_update(model, *args, **kwargs):  # type: ignore[no-untyped-def]
        stmt = original_update(model, *args, **kwargs)

        class _Spy:
            def where(self, *a, **kw):  # type: ignore[no-untyped-def]
                inner = stmt.where(*a, **kw)

                class _Spy2:
                    def values(self, **values):  # type: ignore[no-untyped-def]
                        captured["values"] = values
                        return inner.values(**values)

                return _Spy2()

        return _Spy()

    with patch.object(adapter_module, "update", side_effect=capturing_update):
        await adapter.update(_UPDATE_CMD)

    after = datetime.now(UTC)
    assert "updated_at" in captured["values"]
    ts = captured["values"]["updated_at"]
    assert before <= ts <= after


@pytest.mark.asyncio
async def test_update_writes_only_non_none_fields() -> None:
    """F22 — only non-None command fields (minus routing fields) reach the SQL payload."""
    cmd = UpdateUserCommand(
        target_username="alice",
        requester_user_id=1,
        target_user_id=1,
        name="New Name",
        email=None,
        username=None,
        profile_image_url=None,
    )
    captured: dict = {}

    session = MagicMock()
    session.execute = AsyncMock(return_value=MagicMock())
    session.commit = AsyncMock()

    adapter = _make_adapter(session)

    import app.features.users.update_user.data.adapter as adapter_module

    original_update = adapter_module.update

    def capturing_update(model, *args, **kwargs):  # type: ignore[no-untyped-def]
        stmt = original_update(model, *args, **kwargs)

        class _Spy:
            def where(self, *a, **kw):  # type: ignore[no-untyped-def]
                inner = stmt.where(*a, **kw)

                class _Spy2:
                    def values(self, **values):  # type: ignore[no-untyped-def]
                        captured["values"] = values
                        return inner.values(**values)

                return _Spy2()

        return _Spy()

    with patch.object(adapter_module, "update", side_effect=capturing_update):
        await adapter.update(cmd)

    keys = set(captured["values"].keys())
    assert "name" in keys
    assert "updated_at" in keys
    assert "email" not in keys
    assert "username" not in keys
    assert "profile_image_url" not in keys
    assert "target_username" not in keys
    assert "requester_user_id" not in keys
    assert "target_user_id" not in keys
    assert "requester_user_id" not in keys
