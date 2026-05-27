# FEATURE: migrate_get_post_route_username_to_user_id — use-case unit tests.
#
# Covers: F3, F4, F5, F6, F7, F13, F14, F15.
# Mocks GetPostPort; validates the integer-keyed author check and the
# approved / privileged / missing branches.
import uuid
from datetime import UTC, datetime
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.domain.errors import NotFoundDomainError
from app.features.posts._shared.entities import PostItem
from app.features.posts.get_post.domain.commands import GetPostQuery
from app.features.posts.get_post.domain.use_case import GetPostUseCase

_POST_ID = 1
_AUTHOR_ID = 10
_OTHER_ID = 20
_AUTHOR_USERNAME = "gp54alice"  # display username on PostItem, sourced from the User JOIN

_APPROVED_POST = PostItem(
    id=_POST_ID,
    title="Hello",
    text="Body",
    media_url=None,
    created_at=datetime.now(UTC),
    created_by_user_id=_AUTHOR_ID,
    username=_AUTHOR_USERNAME,
    status="approved",
    post_uuid=uuid.uuid4(),
)
_PENDING_POST = _APPROVED_POST.model_copy(update={"status": "pending"})


def _make_port(*, post: PostItem | None) -> MagicMock:
    port = MagicMock()
    port.get = AsyncMock(return_value=post)
    return port


def _query(**overrides) -> GetPostQuery:
    defaults: dict = {
        "user_id": _AUTHOR_ID,
        "post_id": _POST_ID,
        "requester_user_id": None,
        "requester_is_privileged": False,
    }
    defaults.update(overrides)
    return GetPostQuery(**defaults)


# ── F14: query field shape ────────────────────────────────────────────────────


def test_query_exposes_integer_fields() -> None:
    """F14 — GetPostQuery carries user_id/requester_user_id; old string fields are gone."""
    query = _query(requester_user_id=_AUTHOR_ID)
    assert query.user_id == _AUTHOR_ID
    assert query.requester_user_id == _AUTHOR_ID
    assert not hasattr(query, "username")
    assert not hasattr(query, "requester_username")


# ── F5/F7: port returns None ──────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_raises_not_found_when_port_returns_none() -> None:
    """F7 — port returns None → NotFoundDomainError("Post not found")."""
    use_case = GetPostUseCase(port=_make_port(post=None))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query())
    assert exc_info.value.message == "Post not found"


# ── F3: approved post returned regardless of requester ────────────────────────


@pytest.mark.asyncio
async def test_returns_approved_post_for_unauthenticated() -> None:
    """F3 — approved post, no auth → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_APPROVED_POST))  # type: ignore[arg-type]
    result = await use_case(_query())
    assert result.status == "approved"
    assert result.id == _POST_ID


@pytest.mark.asyncio
async def test_returns_approved_post_for_non_author() -> None:
    """F3 — approved post is public even to a non-author, non-privileged requester."""
    use_case = GetPostUseCase(port=_make_port(post=_APPROVED_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_OTHER_ID))
    assert result.status == "approved"


# ── F4/F13: non-approved post, author bypass by integer id ────────────────────


@pytest.mark.asyncio
async def test_author_can_see_pending_post() -> None:
    """F4/F13 — non-approved post, requester_user_id == user_id → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_AUTHOR_ID))
    assert result.status == "pending"


# ── F5: non-approved post, privileged bypass ──────────────────────────────────


@pytest.mark.asyncio
async def test_privileged_user_can_see_pending_post() -> None:
    """F5 — non-approved post, non-author but privileged → post returned."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    result = await use_case(_query(requester_user_id=_OTHER_ID, requester_is_privileged=True))
    assert result.status == "pending"


# ── F6/F13: non-approved post, neither author nor privileged ──────────────────


@pytest.mark.asyncio
async def test_raises_not_found_for_pending_post_non_author() -> None:
    """F6 — non-approved post, different user, no privilege → NotFoundDomainError."""
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query(requester_user_id=_OTHER_ID))
    assert exc_info.value.message == "Post not found"


@pytest.mark.asyncio
async def test_raises_not_found_for_pending_post_anonymous() -> None:
    """F6/F13 — non-approved post, anonymous (requester_user_id is None) → NotFoundDomainError.

    None == <int> is False, so the anonymous requester fails the author check and
    falls through to the privileged check and the final 404.
    """
    use_case = GetPostUseCase(port=_make_port(post=_PENDING_POST))  # type: ignore[arg-type]
    with pytest.raises(NotFoundDomainError) as exc_info:
        await use_case(_query(requester_user_id=None))
    assert exc_info.value.message == "Post not found"
