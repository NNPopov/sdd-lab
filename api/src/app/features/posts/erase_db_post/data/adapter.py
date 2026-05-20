# FEATURE: erase_db_post — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from sqlalchemy.orm import selectinload

from .....adapters.db.models.post import Post
from .....adapters.db.models.user import User
from ..._shared.entities import PostAuthor
from ..domain.entities import EraseDbPostRecord
from ..domain.ports.erase_db_post_port import EraseDbPostPort


class EraseDbPostAdapter(EraseDbPostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_user_by_username(self, username: str) -> PostAuthor | None:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username, User.is_deleted.is_(False)))
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return PostAuthor.model_validate(user)

    async def find_post(self, post_id: int, owner_id: int) -> EraseDbPostRecord | None:
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
            return EraseDbPostRecord(id=post.id)

    async def hard_delete(self, post_id: int) -> None:
        async with self._session_factory() as session:
            result = await session.execute(
                select(Post).where(Post.id == post_id).options(selectinload(Post.moderation_logs))
            )
            post = result.scalar_one()
            await session.delete(post)
            await session.commit()
