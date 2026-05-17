# FEATURE: list_all_posts — data adapter.
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.user import User
from ..._shared.entities import PostItem, PostPage
from ..domain.commands import ListAllPostsQuery
from ..domain.ports.list_all_posts_port import ListAllPostsPort


class ListAllPostsAdapter(ListAllPostsPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def list(self, query: ListAllPostsQuery) -> PostPage:
        async with self._session_factory() as session:
            apply_filter = not query.requester_is_privileged
            count_stmt = (
                select(func.count())
                .select_from(Post)
                .join(User, Post.created_by_user_id == User.id)
                .where(User.is_deleted == False)  # noqa: E712
                .where(Post.is_deleted == False)  # noqa: E712
            )
            if apply_filter:
                count_stmt = count_stmt.where(Post.status == "approved")
            total_count: int = (await session.execute(count_stmt)).scalar_one()

            offset = (query.page - 1) * query.items_per_page
            rows_stmt = (
                select(Post, User.username)
                .join(User, Post.created_by_user_id == User.id)
                .where(User.is_deleted == False)  # noqa: E712
                .where(Post.is_deleted == False)  # noqa: E712
                .order_by(Post.created_at.desc())
                .offset(offset)
                .limit(query.items_per_page)
            )
            if apply_filter:
                rows_stmt = rows_stmt.where(Post.status == "approved")
            rows = (await session.execute(rows_stmt)).all()

        items = [
            PostItem(
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
            for post, username in rows
        ]
        return PostPage(
            items=items,
            total_count=total_count,
            page=query.page,
            items_per_page=query.items_per_page,
        )
