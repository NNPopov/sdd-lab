# FEATURE: users._shared — ownership policy.
from ....domain.errors import ForbiddenDomainError


def check_owner(requester_id: int, owner_id: int) -> None:
    if requester_id != owner_id:
        raise ForbiddenDomainError()
