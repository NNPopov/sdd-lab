# FEATURE: revise_post — use-case unit tests.
#
# Covers: F4, F5, F6, F7.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts.revise_post.domain.commands import RevisePostCommand
from app.features.posts.revise_post.domain.entities import (
    PostForRevision,
    RevisedPostResult,
    RevisionLogEntry,
)
from app.features.posts.revise_post.domain.use_case import RevisePostUseCase

_POST_UUID = uuid.uuid4()
_POST_ID = 10
_AUTHOR_ID = 5
_OTHER_USER_ID = 99

_POST = PostForRevision(
    id=_POST_ID,
    uuid=_POST_UUID,
    status="changes_requested",
    created_by_user_id=_AUTHOR_ID,
)

_LOG_ENTRY = RevisionLogEntry(
    id=1,
    event_type="author_revision",
    action=None,
    message=None,
    created_at=datetime.now(UTC),
)

_REVISED_RESULT = RevisedPostResult(
    post_uuid=_POST_UUID,
    title="New Title",
    text="Original body.",
    status="pending_review",
    updated_at=datetime.now(UTC),
    log_entry=_LOG_ENTRY,
)


def _make_port(*, post: PostForRevision | None = _POST) -> MagicMock:
    port = MagicMock()
    port.get_post_by_uuid = AsyncMock(return_value=post)
    port.apply_revision = AsyncMock(return_value=_REVISED_RESULT)
    return port


def _cmd(**overrides) -> RevisePostCommand:
    defaults: dict = {
        "post_uuid": _POST_UUID,
        "requester_user_id": _AUTHOR_ID,
        "title": "New Title",
        "text": None,
        "message": None,
    }
    defaults.update(overrides)
    return RevisePostCommand(**defaults)


# ── F4: post not found ────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_when_post_missing() -> None:
    """F4 — get_post_by_uuid returns None → NotFoundDomainError; apply_revision not called."""
    port = _make_port(post=None)
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_cmd())
    assert exc_info.value.message == "Post not found"
    port.apply_revision.assert_not_called()


# ── F5: ownership check ───────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_not_owner() -> None:
    """F5 — requester is not the post author → ForbiddenDomainError; apply_revision not called."""
    port = _make_port()
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_cmd(requester_user_id=_OTHER_USER_ID))
    assert exc_info.value.message == "You may only revise your own posts"
    port.apply_revision.assert_not_called()


# ── F6: status guard — pending_review ────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_status_pending_review() -> None:
    """F6 — post in 'pending_review' → ForbiddenDomainError; apply_revision not called."""
    pending_post = PostForRevision(id=_POST_ID, uuid=_POST_UUID, status="pending_review", created_by_user_id=_AUTHOR_ID)
    port = _make_port(post=pending_post)
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_cmd())
    assert exc_info.value.message == "Post is not in changes_requested status"
    port.apply_revision.assert_not_called()


# ── F6: status guard — approved ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_when_status_approved() -> None:
    """F6 — post in 'approved' → ForbiddenDomainError; apply_revision not called."""
    approved_post = PostForRevision(id=_POST_ID, uuid=_POST_UUID, status="approved", created_by_user_id=_AUTHOR_ID)
    port = _make_port(post=approved_post)
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError) as exc_info:
        await use_case(_cmd())
    assert exc_info.value.message == "Post is not in changes_requested status"
    port.apply_revision.assert_not_called()


# ── F7: happy path — title only ───────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_title_only() -> None:
    """F7 — title provided, text=None; apply_revision called with correct args; result returned."""
    port = _make_port()
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_cmd(title="New Title", text=None, message=None))
    port.apply_revision.assert_called_once_with(_POST_ID, _POST_UUID, "New Title", None, _AUTHOR_ID, None)
    assert result is _REVISED_RESULT


# ── F7: happy path — text only ────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_text_only() -> None:
    """F7 — text provided, title=None; apply_revision called with correct args."""
    port = _make_port()
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_cmd(title=None, text="Updated body.", message=None))
    port.apply_revision.assert_called_once_with(_POST_ID, _POST_UUID, None, "Updated body.", _AUTHOR_ID, None)
    assert result is _REVISED_RESULT


# ── F7: happy path — both fields + message ────────────────────────────────────


@pytest.mark.asyncio
async def test_happy_path_both_fields_and_message() -> None:
    """F7 — title, text, and message all provided; all forwarded to apply_revision."""
    port = _make_port()
    use_case = RevisePostUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_cmd(title="T", text="B", message="Fixed as requested"))
    port.apply_revision.assert_called_once_with(_POST_ID, _POST_UUID, "T", "B", _AUTHOR_ID, "Fixed as requested")
    assert result is _REVISED_RESULT
