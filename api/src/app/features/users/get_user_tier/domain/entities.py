# FEATURE: get_user_tier — domain entities.
from datetime import datetime

from pydantic import BaseModel


class UserNotFound:
    """Adapter signals: no active user row for the given user_id."""


class TierNotFound:
    """Adapter signals: user has tier_id but the tier row is absent."""


class FoundUserTier(BaseModel):
    tier_id: int
    tier_name: str
    tier_created_at: datetime
