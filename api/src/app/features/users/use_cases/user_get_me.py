# FEATURE: users — use case: get current authenticated user.
from typing import Annotated

from fastapi import Depends, Request

from ....shared_dependencies import get_current_user


async def read_users_me(request: Request, current_user: Annotated[dict, Depends(get_current_user)]) -> dict:
    return current_user
