# FEATURE: auth — login, refresh, and logout routes.
from datetime import timedelta
from typing import Annotated, Optional

from fastapi import APIRouter, Cookie, Depends, Request, Response
from fastapi.security import OAuth2PasswordRequestForm
from fastcrud.exceptions.http_exceptions import UnauthorizedException
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from ...adapters.db.session import async_get_db
from ...core.config import settings
from ...core.schemas import Token
from ...core.security import (
    ACCESS_TOKEN_EXPIRE_MINUTES,
    TokenType,
    blacklist_tokens,
    create_access_token,
    create_refresh_token,
    oauth2_scheme,
    verify_token,
)
from ...ports.token_blacklist import TokenBlacklistPort
from .use_cases.authenticate import authenticate_user

router = APIRouter(tags=["login"])


def _get_token_blacklist_adapter() -> TokenBlacklistPort:
    from ...bootstrap.container import container  # noqa: PLC0415

    return container.token_blacklist_adapter()


@router.post("/login", response_model=Token)
async def login_for_access_token(
    response: Response,
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Annotated[AsyncSession, Depends(async_get_db)],
) -> dict[str, str]:
    user = await authenticate_user(username_or_email=form_data.username, password=form_data.password, db=db)
    if not user:
        raise UnauthorizedException("Wrong username, email or password.")

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = await create_access_token(data={"sub": user["username"]}, expires_delta=access_token_expires)

    refresh_token = await create_refresh_token(data={"sub": user["username"]})
    max_age = settings.REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60

    response.set_cookie(
        key="refresh_token", value=refresh_token, httponly=True, secure=True, samesite="lax", max_age=max_age
    )

    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/refresh")
async def refresh_access_token(
    request: Request,
    blacklist: Annotated[TokenBlacklistPort, Depends(_get_token_blacklist_adapter)],
) -> dict[str, str]:
    refresh_token = request.cookies.get("refresh_token")
    if not refresh_token:
        raise UnauthorizedException("Refresh token missing.")

    user_data = await verify_token(refresh_token, TokenType.REFRESH, blacklist)
    if not user_data:
        raise UnauthorizedException("Invalid refresh token.")

    new_access_token = await create_access_token(data={"sub": user_data.username_or_email})
    return {"access_token": new_access_token, "token_type": "bearer"}


@router.post("/logout")
async def logout(
    response: Response,
    access_token: str = Depends(oauth2_scheme),
    refresh_token: Optional[str] = Cookie(None, alias="refresh_token"),
    blacklist: Annotated[TokenBlacklistPort, Depends(_get_token_blacklist_adapter)] = ...,  # type: ignore[assignment]
) -> dict[str, str]:
    try:
        if not refresh_token:
            raise UnauthorizedException("Refresh token not found")

        await blacklist_tokens(access_token=access_token, refresh_token=refresh_token, blacklist=blacklist)
        response.delete_cookie(key="refresh_token")

        return {"message": "Logged out successfully"}

    except JWTError as err:
        raise UnauthorizedException("Invalid token.") from err
