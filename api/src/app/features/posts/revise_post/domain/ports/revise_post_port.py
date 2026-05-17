# FEATURE: revise_post — port protocol.
import uuid
from typing import Protocol, runtime_checkable

from ..entities import PostForRevision, RevisedPostResult


@runtime_checkable
class RevisePostPort(Protocol):
    async def get_post_by_uuid(self, post_uuid: uuid.UUID) -> PostForRevision | None: ...

    async def apply_revision(
        self,
        post_id: int,
        post_uuid: uuid.UUID,
        title: str | None,
        text: str | None,
        author_user_id: int,
        message: str | None,
    ) -> RevisedPostResult: ...
