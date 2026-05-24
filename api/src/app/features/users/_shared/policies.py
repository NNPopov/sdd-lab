# FEATURE: users._shared — ownership policy.
from ....domain.errors import ForbiddenDomainError


def check_owner(requester_user_id: int, owner_user_id: int) -> None:
    if requester_user_id != owner_user_id:
        raise ForbiddenDomainError()
