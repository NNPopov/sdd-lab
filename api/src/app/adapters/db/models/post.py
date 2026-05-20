# STABLE: Infrastructure skeleton. Change only when infra changes.
import uuid as uuid_pkg
from datetime import UTC, datetime
from typing import TYPE_CHECKING

from sqlalchemy import UUID, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from uuid6 import uuid7

from ..base import Base

if TYPE_CHECKING:
    from .post_moderation_log import PostModerationLog


class Post(Base):
    __tablename__ = "post"

    id: Mapped[int] = mapped_column("id", autoincrement=True, nullable=False, unique=True, primary_key=True, init=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    title: Mapped[str] = mapped_column(String(30))
    text: Mapped[str] = mapped_column(String(63206))
    uuid: Mapped[uuid_pkg.UUID] = mapped_column(UUID(as_uuid=True), default_factory=uuid7, unique=True)
    media_url: Mapped[str | None] = mapped_column(String, default=None)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default_factory=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), default=None)
    is_deleted: Mapped[bool] = mapped_column(default=False, index=True)
    status: Mapped[str] = mapped_column(String(20), default="pending_review", index=True)

    moderation_logs: Mapped[list["PostModerationLog"]] = relationship(  # noqa: F821
        cascade="all, delete-orphan",
        lazy="raise",
        init=False,
        repr=False,
        default_factory=list,
    )
