# FEATURE: get_post — use-case unit tests.
#
# Covers: F2, F3, F4, F5.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.posts._shared.entities import PostItem
from app.features.posts.get_post.domain.commands import GetPostQuery
from app.features.posts.get_post.domain.use_case import GetPostUseCase

_POST_ID = 1
_AUTHOR_USERNAME = "alice"
_BOB_USERNAME = "bob"

_APPROVED_POST = PostItem(
    id=_POST_ID,
    title="Hello",
    text="Body",
    media_url=None,
    created_at=datetime.now(UTC),
    created_by_user_id=10,
    username=_AUTHOR_USERNAME,
    status="approved",
    post_uuid=uuid.uuid4(),
)

_PENDING_POST = _APPROVED_POST.model_copy(update={"status": "pending_review"})
_CHANGES_POST = _APPROVED_POST.model_copy(update={"status": "changes_requested"})


def _make_port(*, post: PostItem | None) -> MagicMock:
    port = MagicMock()
    port.get = AsyncMock(return_value=post)
    return port


def _query(**overrides) -> GetPostQuery:
    defaults: dict = {
        "username": _AUTHOR_USERNAME,
        "post_id": _POST_ID,
        "requester_username": None,
        "requester_is_privileged": False,
    }
    defaults.update(overrides)
    return GetPostQuery(**defaults)


# ── F5: port returns None ─────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_port_returns_none() -> None:
    """F5 — port returns None → NotFoundDomainError("Post not found")."""
    use_case = GetPostUseCase(port=_make_port(post=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query())
    assert exc_info.value.message == "Post not found"


# ── F1: approved post, unauthenticated ───────────────────────────────────────


@pytest.mark.asyncio
async def test_returns_approved_post_for_unauthenticated() -> None:
    """F1 — approved post, no auth → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_APPROVED_POST))  # type: ignore[arg-type]
    result = await use_case(_query())
    assert result.status == "approved"
    assert result.id == _POST_ID


# ── F2: non-approved post, author bypass ─────────────────────────────────────


@pytest.mark.asyncio
async def test_author_can_see_pending_post() -> None:
    """F2 — pending_review post, requester is author → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_username=_AUTHOR_USERNAME))
    assert result.status == "pending_review"


@pytest.mark.asyncio
async def test_author_can_see_changes_requested_post() -> None:
    """F2/F13 — changes_requested post, requester is author → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_CHANGES_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_username=_AUTHOR_USERNAME))
    assert result.status == "changes_requested"


# ── F3: non-approved post, privileged bypass ─────────────────────────────────


@pytest.mark.asyncio
async def test_privileged_user_can_see_pending_post() -> None:
    """F3 — pending_review post, requester is privileged → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_username=_BOB_USERNAME, requester_is_privileged=True))
    assert result.status == "pending_review"


@pytest.mark.asyncio
async def test_privileged_user_can_see_changes_requested_post() -> None:
    """F3/F13 — changes_requested post, requester is privileged → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_CHANGES_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_username=_BOB_USERNAME, requester_is_privileged=True))
    assert result.status == "changes_requested"


# ── F4: non-approved post, neither author nor privileged ─────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_for_pending_post_unauthenticated() -> None:
    """F4/F7 — pending_review post, no auth → NotFoundDomainError."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query())
    assert exc_info.value.message == "Post not found"


@pytest.mark.asyncio
async def test_raises_not_found_for_pending_post_non_author() -> None:
    """F4/F8 — pending_review post, different user, no privilege → NotFoundDomainError."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query(requester_username=_BOB_USERNAME))
    assert exc_info.value.message == "Post not found"


@pytest.mark.asyncio
async def test_raises_not_found_for_changes_requested_post_neither() -> None:
    """F4/F12 — changes_requested post, neither author nor privileged → NotFoundDomainError."""
    use_case = GetPostUseCase(port=_make_port(post=_CHANGES_POST))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query(requester_username=_BOB_USERNAME))
    assert exc_info.value.message == "Post not found"
