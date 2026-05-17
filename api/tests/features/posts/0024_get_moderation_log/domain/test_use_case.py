# FEATURE: get_moderation_log — use-case unit tests.
#
# Covers: F3, F4, F5, F6, F7, F8, F9, F10, F11.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import ForbiddenDomainError, NotFoundDomainError
from app.features.posts.get_moderation_log.domain.commands import GetModerationLogQuery
from app.features.posts.get_moderation_log.domain.entities import (
    ModerationLog,
    ModerationLogEntry,
    PostForModerationLog,
)
from app.features.posts.get_moderation_log.domain.use_case import GetModerationLogUseCase

_POST_UUID = uuid.uuid4()
_POST_ID = 42
_AUTHOR_ID = 10
_MODERATOR_ID = 20
_SUPERUSER_ID = 30
_PLAIN_ID = 40

_POST = PostForModerationLog(id=_POST_ID, created_by_user_id=_AUTHOR_ID)

_ENTRY = ModerationLogEntry(
    id=1,
    event_type="moderator_review",
    action="changes_requested",
    message="Please fix.",
    created_at=datetime.now(UTC),
    actor_user_id=_MODERATOR_ID,
    actor_username="mod",
)


def _make_port(*, post: PostForModerationLog | None = _POST, log: list[ModerationLogEntry] | None = None) -> MagicMock:
    port = MagicMock()
    port.get_post_by_uuid = AsyncMock(return_value=post)
    port.get_log = AsyncMock(return_value=log if log is not None else [_ENTRY])
    return port


def _query(**overrides) -> GetModerationLogQuery:
    defaults: dict = {
        "post_uuid": _POST_UUID,
        "requester_user_id": _AUTHOR_ID,
        "requester_is_moderator": False,
        "requester_is_superuser": False,
    }
    defaults.update(overrides)
    return GetModerationLogQuery(**defaults)


# ── F3, F4: post not found ────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_not_found_when_post_missing() -> None:
    """F3, F4 — get_post_by_uuid returns None → NotFoundDomainError; get_log not called."""
    port = _make_port(post=None)
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query())
    assert exc_info.value.message == "Post not found"
    port.get_log.assert_not_called()


# ── F5: forbidden for plain user ─────────────────────────────────────────────


@pytest.mark.asyncio
async def test_forbidden_for_plain_user() -> None:
    """F5 — not author / not moderator / not superuser → ForbiddenDomainError; get_log not called."""
    port = _make_port()
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    with pytest.raises(ForbiddenDomainError):
        await use_case(_query(requester_user_id=_PLAIN_ID))
    port.get_log.assert_not_called()


# ── F6: author access ─────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_author_may_access_log() -> None:
    """F6 — requester is the post author → ModerationLog returned; get_log called."""
    port = _make_port()
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_AUTHOR_ID))
    assert isinstance(result, ModerationLog)
    port.get_log.assert_called_once_with(_POST_ID)


# ── F7: moderator access ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_moderator_may_access_log() -> None:
    """F7 — requester_is_moderator=True (not author) → ModerationLog returned."""
    port = _make_port()
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_MODERATOR_ID, requester_is_moderator=True))
    assert isinstance(result, ModerationLog)
    port.get_log.assert_called_once()


# ── F8: superuser access ──────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_superuser_may_access_log() -> None:
    """F8 — requester_is_superuser=True (not author) → ModerationLog returned."""
    port = _make_port()
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_SUPERUSER_ID, requester_is_superuser=True))
    assert isinstance(result, ModerationLog)
    port.get_log.assert_called_once()


# ── F9: author who is also moderator ─────────────────────────────────────────


@pytest.mark.asyncio
async def test_author_moderator_may_access_log() -> None:
    """F9 — requester is both author and moderator → ModerationLog returned (no conflict)."""
    port = _make_port()
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_AUTHOR_ID, requester_is_moderator=True))
    assert isinstance(result, ModerationLog)


# ── F10: empty log ────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_empty_log_returned_as_valid_result() -> None:
    """F10 — no log entries → ModerationLog(items=[]) returned (valid empty result)."""
    port = _make_port(log=[])
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_query())
    assert result == ModerationLog(items=[])


# ── F11: ordering is adapter's responsibility ─────────────────────────────────


@pytest.mark.asyncio
async def test_entry_order_passed_through_unchanged() -> None:
    """F11 — use-case passes adapter's list through unchanged; ordering is the adapter's concern."""
    entry1 = _ENTRY
    entry2 = _ENTRY.model_copy(update={"id": 2, "event_type": "author_revision"})
    port = _make_port(log=[entry1, entry2])
    use_case = GetModerationLogUseCase(port=port)  # type: ignore[arg-type]
    result = await use_case(_query())
    assert result.items[0].id == entry1.id
    assert result.items[1].id == entry2.id
