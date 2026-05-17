# FEATURE: moderate_post — data adapter.
import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy import update as sa_update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.post_moderation_log import PostModerationLog
from ..domain.entities import ModeratedPostResult, ModerationLogEntry, PostForModeration
from ..domain.ports.moderate_post_port import ModeratePostPort


class ModeratePostAdapter(ModeratePostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_post_by_uuid(self, post_uuid: uuid.UUID) -> PostForModeration | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Post).where(Post.uuid == post_uuid))
            row = result.scalar_one_or_none()
        if row is None:
            return None
        return PostForModeration(
            id=row.id,
            uuid=row.uuid,
            status=row.status,
            created_by_user_id=row.created_by_user_id,
        )

    async def apply_decision(
        self,
        post_id: int,
        post_uuid: uuid.UUID,
        action: str,
        moderator_user_id: int,
        message: str | None,
    ) -> ModeratedPostResult:
        async with self._session_factory() as session:
            await session.execute(
                sa_update(Post).where(Post.id == post_id).values(status=action, updated_at=datetime.now(UTC))
            )

            log_row = PostModerationLog(
                post_id=post_id,
                user_id=moderator_user_id,
                event_type="moderator_review",
                action=action,
                message=message,
            )
            session.add(log_row)
            await session.commit()
            await session.refresh(log_row)

        return ModeratedPostResult(
            post_uuid=post_uuid,
            status=action,
            log_entry=ModerationLogEntry(
                id=log_row.id,
                event_type=log_row.event_type,
                action=log_row.action,
                message=log_row.message,
                created_at=log_row.created_at,
            ),
        )
