# FEATURE: erase_post — data adapter.
from datetime import UTC, datetime

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from ..domain.entities import ErasePostRecord
from ..domain.ports.erase_post_port import ErasePostPort


class ErasePostAdapter(ErasePostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def find_post(self, post_id: int, owner_id: int) -> ErasePostRecord | None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(Post).where(
                    Post.id == post_id,
                    Post.created_by_user_id == owner_id,
                    Post.is_deleted.is_(False),
                )
            )
            post = result.scalar_one_or_none()
            if post is None:
                return None
            return ErasePostRecord(id=post.id)

    async def soft_delete(self, post_id: int) -> None:
        async with self._session_factory() as session:
            await session.execute(
                update(Post).where(Post.id == post_id).values(is_deleted=True, deleted_at=datetime.now(UTC))
            )
            await session.commit()
