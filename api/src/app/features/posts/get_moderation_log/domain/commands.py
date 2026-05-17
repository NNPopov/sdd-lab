# FEATURE: get_moderation_log — domain query.
from uuid import UUID

from pydantic import BaseModel


class GetModerationLogQuery(BaseModel):
    post_uuid: UUID
    requester_user_id: int
    requester_is_moderator: bool
    requester_is_superuser: bool
