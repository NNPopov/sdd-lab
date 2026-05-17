# FEATURE: get_moderation_log — data adapter.
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.post_moderation_log import PostModerationLog
from .....adapters.db.models.user import User
from ..domain.entities import ModerationLogEntry, PostForModerationLog
from ..domain.ports.get_moderation_log_port import GetModerationLogPort


class GetModerationLogAdapter(GetModerationLogPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_post_by_uuid(self, post_uuid: UUID) -> PostForModerationLog | None:
        async with self._session_factory() as session:
            stmt = (
                select(Post.id, Post.created_by_user_id).where(Post.uuid == post_uuid).where(Post.is_deleted == False)  # noqa: E712
            )
            row = (await session.execute(stmt)).one_or_none()
            if row is None:
                return None
            return PostForModerationLog(id=row.id, created_by_user_id=row.created_by_user_id)

    async def get_log(self, post_id: int) -> list[ModerationLogEntry]:
        async with self._session_factory() as session:
            stmt = (
                select(PostModerationLog, User.username)
                .join(User, PostModerationLog.user_id == User.id)
                .where(PostModerationLog.post_id == post_id)
                .order_by(PostModerationLog.created_at.asc())
            )
            rows = (await session.execute(stmt)).all()
            return [
                ModerationLogEntry(
                    id=row.PostModerationLog.id,
                    event_type=row.PostModerationLog.event_type,
                    action=row.PostModerationLog.action,
                    message=row.PostModerationLog.message,
                    created_at=row.PostModerationLog.created_at,
                    actor_user_id=row.PostModerationLog.user_id,
                    actor_username=row.username,
                )
                for row in rows
            ]
