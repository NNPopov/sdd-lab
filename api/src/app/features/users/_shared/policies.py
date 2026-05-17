# FEATURE: users._shared — ownership policy.
from ....domain.errors import ForbiddenDomainError


def check_owner(requester_username: str, owner_username: str) -> None:
    if requester_username != owner_username:
        raise ForbiddenDomainError()
