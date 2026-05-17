# FEATURE: revise_post — data adapter.
import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import select
from sqlalchemy import update as sa_update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.post_moderation_log import PostModerationLog
from ..domain.entities import PostForRevision, RevisedPostResult, RevisionLogEntry
from ..domain.ports.revise_post_port import RevisePostPort


class RevisePostAdapter(RevisePostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_post_by_uuid(self, post_uuid: uuid.UUID) -> PostForRevision | None:
        async with self._session_factory() as session:
            result = await session.execute(select(Post).where(Post.uuid == post_uuid))
            row = result.scalar_one_or_none()
        if row is None:
            return None
        return PostForRevision(
            id=row.id,
            uuid=row.uuid,
            status=row.status,
            created_by_user_id=row.created_by_user_id,
        )

    async def apply_revision(
        self,
        post_id: int,
        post_uuid: uuid.UUID,
        title: str | None,
        text: str | None,
        author_user_id: int,
        message: str | None,
    ) -> RevisedPostResult:
        async with self._session_factory() as session:
            now = datetime.now(UTC)
            values: dict[str, Any] = {
                "status": "pending_review",
                "updated_at": now,
            }
            if title is not None:
                values["title"] = title
            if text is not None:
                values["text"] = text

            await session.execute(sa_update(Post).where(Post.id == post_id).values(**values))

            post_result = await session.execute(select(Post).where(Post.id == post_id))
            post_row = post_result.scalar_one()

            log_row = PostModerationLog(
                post_id=post_id,
                user_id=author_user_id,
                event_type="author_revision",
                action=None,
                message=message,
            )
            session.add(log_row)
            await session.commit()
            await session.refresh(log_row)

        return RevisedPostResult(
            post_uuid=post_uuid,
            title=post_row.title,
            text=post_row.text,
            status=post_row.status,
            updated_at=now,
            log_entry=RevisionLogEntry(
                id=log_row.id,
                event_type=log_row.event_type,
                action=log_row.action,
                message=log_row.message,
                created_at=log_row.created_at,
            ),
        )
