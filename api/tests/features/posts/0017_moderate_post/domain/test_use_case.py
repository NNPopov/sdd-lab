# FEATURE: moderate_post — use-case unit tests.
#
# Covers: F6, F7, F8, F9, F10, F11.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import DuplicateValueDomainError, ForbiddenDomainError, NotFoundDomainError
from app.features.posts.moderate_post.domain.commands import ModeratePostCommand
from app.features.posts.moderate_post.domain.entities import (
    ModeratedPostResult,
    ModerationLogEntry,
    PostForModeration,
)
from app.features.posts.moderate_post.domain.use_case import ModeratePostUseCase

_POST_UUID = uuid.uuid4()
_POST_ID = 10
_AUTHOR_ID = 5
_MODERATOR_ID = 7

_POST = PostForModeration(
    id=_POST_ID,
    uuid=_POST_UUID,
    status="pending_review",
    created_by_user_id=_AUTHOR_ID,
)

_LOG_ENTRY = ModerationLogEntry(
    id=1,
    event_type="moderator_review",
    action="approved",
    message=None,
    created_at=datetime.now(UTC),
)

_APPROVED_RESULT = ModeratedPostResult(
    post_uuid=_POST_UUID,
    status="approved",
    log_entry=_LOG_ENTRY,
)


def _make_port(*, post: PostForModeration | None = _POST) -> MagicMock:
    port = MagicMock()
    port.get_post_by_uuid = AsyncMock(return_value=post)
    port.apply_decision = AsyncMock(return_value=_APPROVED_RESULT)
    return port


def _cmd(**overrides) -> ModeratePostCommand:
    defaults: dict = {
        "post_uuid": _POST_UUID,
        "requester_user_id": _MODERATOR_ID,
        "requester_is_privileged": True,
        "action": "approved",
        "message": None,
    }
    defaults.update(overrides)
    return ModeratePostCommand(**defaults)


# ── F6: privilege check ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_not_privileged() -> None:
    """F6 — requester_is_privileged=False → ForbiddenDomainError; get_post_by_uuid not called."""
    port = _make_port()
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_cmd(requester_is_privileged=False))
    assert exc_info.value.message == "Moderator or superuser privilege required"
    port.get_post_by_uuid.assert_not_called()


# ── F7: post not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_when_post_missing() -> None:
    """F7 — get_post_by_uuid returns None → NotFoundDomainError; apply_decision not called."""
    port = _make_port(post=None)
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_cmd())
    assert exc_info.value.message == "Post not found"
    port.apply_decision.assert_not_called()


# ── F8: self-review guard ─────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_on_self_review() -> None:
    """F8 — requester is the post author → ForbiddenDomainError (self-review)."""
    own_post = PostForModeration(
        id=_POST_ID, uuid=_POST_UUID, status="pending_review", created_by_user_id=_MODERATOR_ID
    )
    port = _make_port(post=own_post)
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_cmd())
    assert exc_info.value.message == "Moderators may not review their own posts"


# ── F9: terminal state guard ──────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_duplicate_error_when_already_approved() -> None:
    """F9 — post.status == 'approved' → DuplicateValueDomainError."""
    approved_post = PostForModeration(id=_POST_ID, uuid=_POST_UUID, status="approved", created_by_user_id=_AUTHOR_ID)
    port = _make_port(post=approved_post)
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(DuplicateValueDomainError) as exc_info:
        await use_case(_cmd())
    assert exc_info.value.message == "Post is already approved"


# ── F10: message required guard ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_changes_requested_without_message() -> None:
    """F10 — action='changes_requested' with message=None → ForbiddenDomainError."""
    port = _make_port()
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_cmd(action="changes_requested", message=None))
    assert exc_info.value.message == "A message is required when requesting changes"


# ── F11: happy path — approve ─────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_approve() -> None:
    """F11 — all guards pass, action='approved' → apply_decision called; result returned."""
    port = _make_port()
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_cmd(action="approved", message=None))
    port.apply_decision.assert_called_once_with(_POST_ID, _POST_UUID, "approved", _MODERATOR_ID, None)
    assert result.status == "approved"
    assert result.log_entry.event_type == "moderator_review"


# ── F11: happy path — changes_requested ──────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_changes_requested() -> None:
    """F11 — action='changes_requested' with message → apply_decision called correctly."""
    changes_result = _APPROVED_RESULT.model_copy(
        update={
            "status": "changes_requested",
            "log_entry": _LOG_ENTRY.model_copy(update={"action": "changes_requested", "message": "Please fix typos"}),
        }
    )
    port = _make_port()
    port.apply_decision = AsyncMock(return_value=changes_result)
    use_case = ModeratePostUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_cmd(action="changes_requested", message="Please fix typos"))
    port.apply_decision.assert_called_once_with(
        _POST_ID, _POST_UUID, "changes_requested", _MODERATOR_ID, "Please fix typos"
    )
    assert result.status == "changes_requested"
    assert result.log_entry.message == "Please fix typos"
