# FEATURE: moderate_post — port protocol.
import uuid
from typing import Protocol, runtime_checkable

from ..entities import ModeratedPostResult, PostForModeration


@runtime_checkable
class ModeratePostPort(Protocol):
    async def get_post_by_uuid(self, post_uuid: uuid.UUID) -> PostForModeration | None: ...

    async def apply_decision(
        self,
        post_id: int,
        post_uuid: uuid.UUID,
        action: str,
        moderator_user_id: int,
        message: str | None,
    ) -> ModeratedPostResult: ...
