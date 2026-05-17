# FEATURE: delete_user — TokenBlacklistService unit tests.
#
# Covers: F11.
from datetime import UTC, datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from jose import jwt
from jose.exceptions import JWTError

from app.core.config import settings
from app.core.token_blacklist_service import TokenBlacklistService


def _make_service(session_mock: MagicMock) -> TokenBlacklistService:
    factory = MagicMock()
    factory.return_value.__aenter__ = AsyncMock(return_value=session_mock)
    factory.return_value.__aexit__ = AsyncMock(return_value=False)
    return TokenBlacklistService(session_factory=factory)


def _make_token(expire_delta: timedelta = timedelta(minutes=30)) -> str:
    expire = datetime.now(UTC).replace(tzinfo=None) + expire_delta
    payload = {"sub": "alice", "exp": expire, "token_type": "access"}
    return jwt.encode(payload, settings.SECRET_KEY.get_secret_value(), algorithm=settings.ALGORITHM)


# ── F11: valid token → create called with correct expires_at ─────────────────


@pytest.mark.asyncio
async def test_blacklist_creates_record_with_correct_expires_at() -> None:
    """F11 — valid JWT → crud_token_blacklist.create called with matching expires_at."""
    import app.core.token_blacklist_service as service_module
    from app.core.schemas import TokenBlacklistCreate

    session = MagicMock()
    service = _make_service(session)

    token = _make_token()
    payload = jwt.decode(token, settings.SECRET_KEY.get_secret_value(), algorithms=[settings.ALGORITHM])
    expected_exp = payload["exp"]

    mock_create = AsyncMock(return_value=None)
    with patch.object(service_module.crud_token_blacklist, "create", mock_create):
        await service.blacklist(token)

    mock_create.assert_called_once()
    _, call_kwargs = mock_create.call_args
    created: TokenBlacklistCreate = call_kwargs["object"]
    assert created.token == token
    assert abs(created.expires_at.timestamp() - expected_exp) < 1


# ── F11: invalid token → JWTError propagates ─────────────────────────────────


@pytest.mark.asyncio
async def test_blacklist_propagates_jwt_error_for_invalid_token() -> None:
    """F11 — malformed JWT → JWTError propagates unchanged."""
    session = MagicMock()
    service = _make_service(session)

    with pytest.raises(JWTError):
        await service.blacklist("not.a.valid.token")
