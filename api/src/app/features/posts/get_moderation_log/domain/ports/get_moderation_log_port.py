# FEATURE: get_moderation_log — port protocol.
from typing import Protocol, runtime_checkable
from uuid import UUID

from ..entities import ModerationLogEntry, PostForModerationLog


@runtime_checkable
class GetModerationLogPort(Protocol):
    async def get_post_by_uuid(self, post_uuid: UUID) -> PostForModerationLog | None: ...
    async def get_log(self, post_id: int) -> list[ModerationLogEntry]: ...
