# FEATURE: revoke_moderator — use-case unit tests.
#
# Covers: F3 (forbidden), F4 (not found), F5 (not a moderator), F6 (happy path).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from app.features.users.revoke_moderator.domain.commands import RevokeModeratorCommand
from app.features.users.revoke_moderator.domain.entities import RevokedUser
from app.features.users.revoke_moderator.domain.use_case import RevokeModeratorUseCase

_TARGET = RevokedUser(
    id=42,
    name="Target User",
    username="targetuser",
    email="target@example.com",
    profile_image_url="https://example.com/img.png",
    tier_id=None,
    is_moderator=True,
)

_CMD = RevokeModeratorCommand(
    target_username="targetuser",
    requester_is_superuser=True,
)


def _make_port(*, target: RevokedUser | None = _TARGET) -> MagicMock:
    port = MagicMock()
    port.get_by_username = AsyncMock(return_value=target)
    port.revoke = AsyncMock(return_value=_TARGET.model_copy(update={"is_moderator": False}))
    return port


# ── F3: superuser check ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_not_superuser() -> None:
    """F3 — requester_is_superuser=False → ForbiddenDomainError; get_by_username not called."""
    port = _make_port()
    use_case = RevokeModeratorUseCase(port=port)  # type: ignore[arg-type]
    cmd = RevokeModeratorCommand(
        target_username="targetuser",
        requester_is_superuser=False,
    )
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "Superuser privilege required"
    port.get_by_username.assert_not_called()


# ── F4: target not found ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_when_port_returns_none() -> None:
    """F4 — get_by_username returns None → NotFoundDomainError; revoke not called."""
    port = _make_port(target=None)
    use_case = RevokeModeratorUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"
    port.revoke.assert_not_called()


# ── F5: not a moderator ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_error_when_not_a_moderator() -> None:
    """F5 — target.is_moderator=False → DuplicateValueDomainError; revoke not called."""
    not_mod = _TARGET.model_copy(update={"is_moderator": False})
    port = _make_port(target=not_mod)
    use_case = RevokeModeratorUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User is not a moderator"
    port.revoke.assert_not_called()


# ── F6: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_returns_revoked_user() -> None:
    """F6 — all checks pass → port.revoke called; result returned unchanged."""
    port = _make_port()
    use_case = RevokeModeratorUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)
    port.revoke.assert_called_once_with("targetuser")
    assert result.is_moderator is False
    assert result.username == "targetuser"
