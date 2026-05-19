# FEATURE: update_post — data adapter.
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy import update as sqlalchemy_update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.user import User
from ..._shared.entities import PostAuthor, PostItem
from ..domain.commands import UpdatePostCommand
from ..domain.ports.update_post_port import UpdatePostPort


class UpdatePostAdapter(UpdatePostPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get_user_by_username(self, username: str) -> PostAuthor | None:
        async with self._session_factory() as session:
            result = await session.execute(select(User).where(User.username == username, User.is_deleted.is_(False)))
            user = result.scalar_one_or_none()
            if user is None:
                return None
            return PostAuthor.model_validate(user)

    async def get_post_by_id(self, post_id: int) -> PostItem | None:
        async with self._session_factory() as session:
            stmt = (
                select(Post, User.username)
                .join(User, Post.created_by_user_id == User.id)
                .where(Post.id == post_id)
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

    async def update(self, command: UpdatePostCommand) -> None:
        content_fields = {"title": command.title, "text": command.text, "media_url": command.media_url}
        update_values: dict[str, object] = {k: v for k, v in content_fields.items() if v is not None}
        update_values["updated_at"] = datetime.now(UTC)

        async with self._session_factory() as session:
            await session.execute(sqlalchemy_update(Post).where(Post.id == command.post_id).values(**update_values))
            await session.commit()
