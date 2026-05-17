# FEATURE: refactor_create_user_adapter — adapter unit tests.
#
# Covers F1–F9 from requirements.md.
# Red-state trigger: F3, F6, F9 — current adapter wraps unexpected exceptions
# as UnknownDomainError; post-refactor they must propagate unchanged.
from unittest.mock import AsyncMock, MagicMock

import pytest
from sqlalchemy.exc import IntegrityError

from app.domain.errors import DuplicateValueDomainError
from app.features.users.create_user.data.adapter import CreateUserAdapter
from app.features.users.create_user.domain.commands import CreateUserInternalCommand

_CMD = CreateUserInternalCommand(
    name="Bob Refactor",
    username="bobrefactor",
    email="bob.refactor@example.com",
    hashed_password="hashed_pw",
)


def _make_adapter(session_mock: MagicMock) -> CreateUserAdapter:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return CreateUserAdapter(session_factory=factory)


# ── email_exists ──────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_email_exists_returns_true_when_row_found() -> None:
    """F1 — row present → True."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = object()
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).email_exists("bob.refactor@example.com") is True


@pytest.mark.asyncio
async def test_email_exists_returns_false_when_no_row() -> None:
    """F2 — no row → False."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).email_exists("bob.refactor@example.com") is False


@pytest.mark.asyncio
async def test_email_exists_propagates_original_exception() -> None:
    """F3 — non-DomainError propagates unchanged; adapter must NOT wrap it."""
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))
    with pytest.raises(RuntimeError, match="db boom"):
        await _make_adapter(session).email_exists("bob.refactor@example.com")


# ── username_exists ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_username_exists_returns_true_when_row_found() -> None:
    """F4 — row present → True."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = object()
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).username_exists("bobrefactor") is True


@pytest.mark.asyncio
async def test_username_exists_returns_false_when_no_row() -> None:
    """F5 — no row → False."""
    session = MagicMock()
    result = MagicMock()
    result.scalar_one_or_none.return_value = None
    session.execute = AsyncMock(return_value=result)
    assert await _make_adapter(session).username_exists("bobrefactor") is False


@pytest.mark.asyncio
async def test_username_exists_propagates_original_exception() -> None:
    """F6 — non-DomainError propagates unchanged; adapter must NOT wrap it."""
    session = MagicMock()
    session.execute = AsyncMock(side_effect=RuntimeError("db boom"))
    with pytest.raises(RuntimeError, match="db boom"):
        await _make_adapter(session).username_exists("bobrefactor")


# ── create ────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_create_returns_created_user_on_success() -> None:
    """F7 — success path returns a populated CreatedUser."""
    from app.adapters.db.models.user import User

    user_model = MagicMock(spec=User)
    user_model.id = 1
    user_model.name = "Bob Refactor"
    user_model.username = "bobrefactor"
    user_model.email = "bob.refactor@example.com"
    user_model.profile_image_url = "https://example.com/img.png"
    user_model.tier_id = None

    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock()
    session.refresh = AsyncMock()

    # After refresh the adapter reads fields off the model.
    # Simulate by having the session hold the model in `scalar_one`.
    adapter = _make_adapter(session)

    # Patch User constructor to return our model so the adapter builds it.
    import app.features.users.create_user.data.adapter as adapter_module

    original_user = adapter_module.User

    class _FakeUser:
        def __init__(self, **kwargs: object) -> None:
            self.id = user_model.id
            self.name = user_model.name
            self.username = user_model.username
            self.email = user_model.email
            self.profile_image_url = user_model.profile_image_url
            self.tier_id = user_model.tier_id

    adapter_module.User = _FakeUser  # type: ignore[assignment]
    try:
        result = await adapter.create(_CMD)
    finally:
        adapter_module.User = original_user  # type: ignore[assignment]

    assert result.username == "bobrefactor"
    assert result.email == "bob.refactor@example.com"


@pytest.mark.asyncio
async def test_create_integrity_error_maps_to_duplicate_value() -> None:
    """F8 — IntegrityError at commit → DuplicateValueDomainError."""
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock(side_effect=IntegrityError("dup", {}, None))
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await _make_adapter(session).create(_CMD)
    assert "already registered" in exc_info.value.message


@pytest.mark.asyncio
async def test_create_propagates_non_integrity_error_from_commit() -> None:
    """F9 — non-IntegrityError from commit propagates unchanged; adapter must NOT wrap it."""
    session = MagicMock()
    session.add = MagicMock()
    session.commit = AsyncMock(side_effect=RuntimeError("unexpected commit failure"))
    with pytest.raises(RuntimeError, match="unexpected commit failure"):
        await _make_adapter(session).create(_CMD)
