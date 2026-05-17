# FEATURE: create_post — data adapter.
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.user import User
from ..domain.commands import CreatePostInternalCommand
from ..domain.entities import CreatedPost, PostAuthor
from ..domain.ports.create_post_port import CreatePostPort


class CreatePostAdapter(CreatePostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_user_by_username(self, username: str) -> PostAuthor | None:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username, User.is_deleted.is_(False)))
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return PostAuthor.model_validate(user)

    async def create(self, command: CreatePostInternalCommand) -> CreatedPost:
        async with self._session_factory() as session:
            post = Post(
                created_by_user_id=command.created_by_user_id,
                title=command.title,
                text=command.text,
                media_url=command.media_url,
                status="pending_review",
            )
            session.add(post)
            await session.commit()
            await session.refresh(post)
            return CreatedPost(
                id=post.id,
                title=post.title,
                text=post.text,
                media_url=post.media_url,
                created_by_user_id=post.created_by_user_id,
                created_at=post.created_at,
                status=post.status,
                post_uuid=post.uuid,
            )
