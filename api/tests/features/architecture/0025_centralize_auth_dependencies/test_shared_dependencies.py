# FEATURE: centralize_auth_dependencies — unit tests for shared_dependencies auth helpers.
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastcrud.exceptions.http_exceptions import ForbiddenException, UnauthorizedException
from sqlalchemy.ext.asyncio import AsyncSession

from app.shared_dependencies import (
    _get_user_by_credential,
    get_current_moderator_or_superuser,
    get_current_superuser,
    get_current_user,
    get_optional_user,
)

pytestmark = pytest.mark.asyncio


def _make_db(scalar_result: object) -> AsyncSession:
    result_mock = MagicMock()
    result_mock.scalar_one_or_none.return_value = scalar_result
    db = MagicMock(spec=AsyncSession)
    db.execute = AsyncMock(return_value=result_mock)
    return db


def _make_row(
    *,
    id: int = 1,
    name: str = "Alice",
    username: str = "alice",
    email: str = "alice@example.com",
    profile_image_url: str = "https://www.profileimageurl.com",
    is_superuser: bool = False,
    is_moderator: bool = False,
    tier_id: int | None = 1,
) -> MagicMock:
    row = MagicMock()
    row.id = id
    row.name = name
    row.username = username
    row.email = email
    row.profile_image_url = profile_image_url
    row.is_superuser = is_superuser
    row.is_moderator = is_moderator
    row.tier_id = tier_id
    return row


# ── _get_user_by_credential ────────────────────────────────────────────────


async def test_returns_allowlisted_dict_on_match():
    """F2, F4: username credential returns the eight-key allowlisted dict."""
    db = _make_db(_make_row())

    result = await _get_user_by_credential(db, "alice")

    assert result == {
        "id": 1,
        "name": "Alice",
        "username": "alice",
        "email": "alice@example.com",
        "profile_image_url": "https://www.profileimageurl.com",
        "is_superuser": False,
        "is_moderator": False,
        "tier_id": 1,
    }
    assert "hashed_password" not in result
    assert set(result.keys()) == {
        "id",
        "name",
        "username",
        "email",
        "profile_image_url",
        "is_superuser",
        "is_moderator",
        "tier_id",
    }


async def test_returns_none_when_no_row_matches():
    """F1, F5: missing or soft-deleted user returns None."""
    db = _make_db(None)

    result = await _get_user_by_credential(db, "deleted_user")

    assert result is None


async def test_routes_by_at_sign_to_email_branch():
    """F3: credential with '@' executes an email-column WHERE clause."""
    db = _make_db(_make_row(email="alice@example.com"))

    await _get_user_by_credential(db, "alice@example.com")

    stmt_arg = db.execute.call_args[0][0]
    compiled = str(stmt_arg.compile(compile_kwargs={"literal_binds": True}))
    assert '"user".email' in compiled or "user.email" in compiled


async def test_routes_without_at_sign_to_username_branch():
    """F4: credential without '@' executes a username-column WHERE clause."""
    db = _make_db(_make_row(username="alice"))

    await _get_user_by_credential(db, "alice")

    stmt_arg = db.execute.call_args[0][0]
    compiled = str(stmt_arg.compile(compile_kwargs={"literal_binds": True}))
    assert "username" in compiled


async def test_filters_out_is_deleted_true_rows():
    """F5: is_deleted predicate is present in the generated SQL."""
    db = _make_db(None)

    await _get_user_by_credential(db, "ghost")

    stmt_arg = db.execute.call_args[0][0]
    compiled = str(stmt_arg.compile(compile_kwargs={"literal_binds": True}))
    assert "is_deleted" in compiled


# ── get_current_user ───────────────────────────────────────────────────────


async def test_raises_unauthorized_when_token_invalid(mocker):
    """F6: raises UnauthorizedException when verify_token returns None."""
    mocker.patch(
        "app.shared_dependencies.verify_token",
        new=mocker.AsyncMock(return_value=None),
    )
    mock_get_credential = mocker.patch(
        "app.shared_dependencies._get_user_by_credential",
        new=mocker.AsyncMock(),
    )
    db = MagicMock(spec=AsyncSession)
    blacklist = AsyncMock()

    with pytest.raises(UnauthorizedException):
        await get_current_user(token="garbage.token.here", db=db, blacklist=blacklist)

    mock_get_credential.assert_not_awaited()


async def test_raises_unauthorized_when_user_not_found(mocker):
    """F7: raises UnauthorizedException when _get_user_by_credential returns None."""
    token_data = MagicMock()
    token_data.username_or_email = "alice"
    mocker.patch(
        "app.shared_dependencies.verify_token",
        new=mocker.AsyncMock(return_value=token_data),
    )
    mocker.patch(
        "app.shared_dependencies._get_user_by_credential",
        new=mocker.AsyncMock(return_value=None),
    )
    db = MagicMock(spec=AsyncSession)
    blacklist = AsyncMock()

    with pytest.raises(UnauthorizedException):
        await get_current_user(token="valid.token.here", db=db, blacklist=blacklist)


async def test_returns_user_dict_on_success(mocker):
    """F8: returns the user dict produced by _get_user_by_credential on the happy path."""
    user_dict = {
        "id": 1,
        "name": "Alice",
        "username": "alice",
        "email": "a@b.com",
        "profile_image_url": "https://www.profileimageurl.com",
        "is_superuser": False,
        "is_moderator": False,
        "tier_id": 1,
    }
    token_data = MagicMock()
    token_data.username_or_email = "alice"
    mocker.patch(
        "app.shared_dependencies.verify_token",
        new=mocker.AsyncMock(return_value=token_data),
    )
    mocker.patch(
        "app.shared_dependencies._get_user_by_credential",
        new=mocker.AsyncMock(return_value=user_dict),
    )
    db = MagicMock(spec=AsyncSession)
    blacklist = AsyncMock()

    result = await get_current_user(token="valid.token.here", db=db, blacklist=blacklist)

    assert result == user_dict


# ── get_optional_user ──────────────────────────────────────────────────────


async def test_returns_none_for_missing_authorization_header(mocker):
    """F9: returns None when Authorization header is absent."""
    request = MagicMock()
    request.headers.get.return_value = None
    db = MagicMock(spec=AsyncSession)

    result = await get_optional_user(request=request, db=db)

    assert result is None


async def test_returns_none_for_non_bearer_format(mocker):
    """F10: returns None when Authorization header is not Bearer format."""
    request = MagicMock()
    request.headers.get.return_value = "Basic dXNlcjpwYXNz"
    db = MagicMock(spec=AsyncSession)

    result = await get_optional_user(request=request, db=db)

    assert result is None


async def test_returns_none_when_verify_token_returns_none(mocker):
    """F11: returns None when verify_token returns None (invalid/expired token)."""
    request = MagicMock()
    request.headers.get.return_value = "Bearer expired.token.here"
    mocker.patch(
        "app.shared_dependencies.verify_token",
        new=mocker.AsyncMock(return_value=None),
    )
    db = MagicMock(spec=AsyncSession)

    result = await get_optional_user(request=request, db=db)

    assert result is None


# ── get_current_superuser ──────────────────────────────────────────────────


async def test_get_current_superuser_raises_forbidden_for_non_superuser():
    """F13: raises ForbiddenException when is_superuser is falsy."""
    current_user = {"id": 1, "username": "alice", "is_superuser": False}

    with pytest.raises(ForbiddenException):
        await get_current_superuser(current_user=current_user)


# ── get_current_moderator_or_superuser ─────────────────────────────────────


async def test_get_current_moderator_or_superuser_raises_forbidden_for_regular_user():
    """F14: raises ForbiddenException when neither is_moderator nor is_superuser."""
    current_user = {"id": 1, "username": "alice", "is_superuser": False, "is_moderator": False}

    with pytest.raises(ForbiddenException):
        await get_current_moderator_or_superuser(current_user=current_user)
