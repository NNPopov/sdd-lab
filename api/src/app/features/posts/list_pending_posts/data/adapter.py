# FEATURE: list_pending_posts — data adapter.
from collections import defaultdict

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from .....adapters.db.models.post import Post
from .....adapters.db.models.post_moderation_log import PostModerationLog
from .....adapters.db.models.user import User
from ..domain.commands import ListPendingPostsQuery
from ..domain.entities import PendingModerationLogEntry, PendingPostItem, PendingPostPage
from ..domain.ports.list_pending_posts_port import ListPendingPostsPort

_PENDING_STATUSES = ("pending_review", "changes_requested")


class ListPendingPostsAdapter(ListPendingPostsPort):
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def list(self, query: ListPendingPostsQuery) -> PendingPostPage:
        async with self._session_factory() as session:
            count_stmt = (
                select(func.count())
                .select_from(Post)
                .join(User, Post.created_by_user_id == User.id)
                .where(Post.status.in_(_PENDING_STATUSES))
                .where(Post.is_deleted == False)  # noqa: E712
                .where(User.is_deleted == False)  # noqa: E712
            )
            total_count: int = (await session.execute(count_stmt)).scalar_one()

            offset = (query.page - 1) * query.items_per_page
            rows_stmt = (
                select(Post, User.username)
                .join(User, Post.created_by_user_id == User.id)
                .where(Post.status.in_(_PENDING_STATUSES))
                .where(Post.is_deleted == False)  # noqa: E712
                .where(User.is_deleted == False)  # noqa: E712
                .order_by(Post.created_at.desc())
                .offset(offset)
                .limit(query.items_per_page)
            )
            post_rows = (await session.execute(rows_stmt)).all()

            post_ids = [row.Post.id for row in post_rows]
            if post_ids:
                log_stmt = (
                    select(PostModerationLog)
                    .where(PostModerationLog.post_id.in_(post_ids))
                    .order_by(PostModerationLog.created_at.asc())
                )
                log_rows = (await session.execute(log_stmt)).scalars().all()
            else:
                log_rows = []

        logs_by_post: dict[int, list[PendingModerationLogEntry]] = defaultdict(list)
        for log in log_rows:
            logs_by_post[log.post_id].append(
                PendingModerationLogEntry(
                    id=log.id,
                    event_type=log.event_type,
                    action=log.action,
                    message=log.message,
                    created_at=log.created_at,
                )
            )

        items = [
            PendingPostItem(
                post_uuid=row.Post.uuid,
                title=row.Post.title,
                text=row.Post.text,
                media_url=row.Post.media_url,
                status=row.Post.status,
                created_at=row.Post.created_at,
                updated_at=row.Post.updated_at,
                author_username=row.username,
                moderation_log=logs_by_post[row.Post.id],
            )
            for row in post_rows
        ]

        return PendingPostPage(
            items=items,
            total_count=total_count,
            page=query.page,
            items_per_page=query.items_per_page,
        )
