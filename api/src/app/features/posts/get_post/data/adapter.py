# FEATURE: get_post — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.user import User
from ..._shared.entities import PostItem
from ..domain.commands import GetPostQuery
from ..domain.ports.get_post_port import GetPostPort


class GetPostAdapter(GetPostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, query: GetPostQuery) -> PostItem | None:
        async with self._session_factory() as session:
            stmt = (
                select(Post, User.username)
                .join(User, Post.created_by_user_id == User.id)
                .where(User.username == query.username)
                .where(Post.id == query.post_id)
                .where(User.is_deleted == False)  # noqa: E712
                .where(Post.is_deleted == False)  # noqa: E712
            )
            row = (await session.execute(stmt)).one_or_none()
            if row is None:
                return None
            post, username = row
            return PostItem(
                id=post.id,
                title=post.title,
                text=post.text,
                media_url=post.media_url,
                created_at=post.created_at,
                created_by_user_id=post.created_by_user_id,
                username=username,
                status=post.status,
                post_uuid=post.uuid,
            )
