# FEATURE: assign_moderator — use-case unit tests.
#
# Covers: F4 (forbidden), F5 (not found), F6 (already moderator), F7 (happy path).
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from app.features.users.assign_moderator.domain.commands import AssignModeratorCommand
from app.features.users.assign_moderator.domain.entities import AssignedUser
from app.features.users.assign_moderator.domain.use_case import AssignModeratorUseCase

_TARGET = AssignedUser(
    id=42,
    name="Target User",
    username="targetuser",
    email="target@example.com",
    profile_image_url="https://example.com/img.png",
    tier_id=None,
    is_moderator=False,
)

_CMD = AssignModeratorCommand(
    target_user_id=42,
    requester_id=1,
    requester_is_superuser=True,
)


def _make_port(*, target: AssignedUser | None = _TARGET) -> MagicMock:
    port = MagicMock()
    port.get_by_id = AsyncMock(return_value=target)
    port.assign = AsyncMock(return_value=_TARGET.model_copy(update={"is_moderator": True}))
    return port


# ── F4: superuser check ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_not_superuser() -> None:
    """F4 — requester_is_superuser=False → ForbiddenDomainError; get_by_id not called."""
    port = _make_port()
    use_case = AssignModeratorUseCase(port=port)  # type: ignore[arg-type]
    cmd = AssignModeratorCommand(
        target_user_id=42,
        requester_id=1,
        requester_is_superuser=False,
    )
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(cmd)
    assert exc_info.value.message == "Superuser privilege required"
    port.get_by_id.assert_not_called()


# ── F5: target not found ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_when_port_returns_none() -> None:
    """F5 — get_by_id returns None → NotFoundDomainError; assign not called."""
    port = _make_port(target=None)
    use_case = AssignModeratorUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User not found"
    port.assign.assert_not_called()


# ── F6: already moderator ─────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_error_when_already_moderator() -> None:
    """F6 — target.is_moderator=True → DuplicateValueDomainError."""
    already_mod = _TARGET.model_copy(update={"is_moderator": True})
    port = _make_port(target=already_mod)
    use_case = AssignModeratorUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_CMD)
    assert exc_info.value.message == "User is already a moderator"


# ── F7: happy path ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_returns_assigned_user() -> None:
    """F7 — all checks pass → port.assign called; result returned unchanged."""
    port = _make_port()
    use_case = AssignModeratorUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_CMD)
    port.assign.assert_called_once_with(42, 1)
    assert result.is_moderator is True
    assert result.username == "targetuser"
