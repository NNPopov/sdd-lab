# FEATURE: get_user_tier — port protocol.
from typing import Protocol, runtime_checkable

from ..commands import GetUserTierQuery
from ..entities import FoundUserTier, TierNotFound, UserNotFound


@runtime_checkable
class GetUserTierPort(Protocol):
    async def get(self, query: GetUserTierQuery) -> FoundUserTier | None | UserNotFound | TierNotFound:
        """Return port state for the given user_id query.

        FoundUserTier  — user exists and has a valid tier.
        None           — user exists but tier_id is None.
        UserNotFound() — no active user row for the given user_id.
        TierNotFound() — user has a tier_id but the tier row is absent.
        """
        ...
