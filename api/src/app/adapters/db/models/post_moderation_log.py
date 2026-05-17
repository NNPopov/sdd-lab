# STABLE: Infrastructure skeleton. Change only when infra changes.
from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from ..base import Base


class PostModerationLog(Base):
    __tablename__ = "post_moderation_log"

    id: Mapped[int] = mapped_column(autoincrement=True, primary_key=True, init=False)
    post_id: Mapped[int] = mapped_column(ForeignKey("post.id"), index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("user.id"), index=True)
    event_type: Mapped[str] = mapped_column(String(20))
    action: Mapped[str | None] = mapped_column(String(20), default=None)
    message: Mapped[str | None] = mapped_column(String(2000), default=None)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default_factory=lambda: datetime.now(UTC), init=False
    )
