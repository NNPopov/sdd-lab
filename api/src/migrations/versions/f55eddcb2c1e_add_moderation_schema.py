"""add_moderation_schema

Revision ID: f55eddcb2c1e
Revises:
Create Date: 2026-05-15 16:06:28.436850

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f55eddcb2c1e'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'post_moderation_log',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('post_id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('event_type', sa.String(length=20), nullable=False),
        sa.Column('action', sa.String(length=20), nullable=True),
        sa.Column('message', sa.String(length=2000), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['post_id'], ['post.id']),
        sa.ForeignKeyConstraint(['user_id'], ['user.id']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_post_moderation_log_post_id'), 'post_moderation_log', ['post_id'], unique=False)
    op.create_index(op.f('ix_post_moderation_log_user_id'), 'post_moderation_log', ['user_id'], unique=False)

    op.add_column('post', sa.Column('status', sa.String(length=20), server_default='pending_review', nullable=False))
    op.create_index(op.f('ix_post_status'), 'post', ['status'], unique=False)

    op.add_column('user', sa.Column('is_moderator', sa.Boolean(), server_default='false', nullable=False))
    op.add_column('user', sa.Column('moderator_granted_by_user_id', sa.Integer(), nullable=True))
    op.create_index(op.f('ix_user_is_moderator'), 'user', ['is_moderator'], unique=False)
    op.create_index(op.f('ix_user_moderator_granted_by_user_id'), 'user', ['moderator_granted_by_user_id'], unique=False)
    op.create_foreign_key(None, 'user', 'user', ['moderator_granted_by_user_id'], ['id'])


def downgrade() -> None:
    op.drop_constraint(None, 'user', type_='foreignkey')
    op.drop_index(op.f('ix_user_moderator_granted_by_user_id'), table_name='user')
    op.drop_index(op.f('ix_user_is_moderator'), table_name='user')
    op.drop_column('user', 'moderator_granted_by_user_id')
    op.drop_column('user', 'is_moderator')

    op.drop_index(op.f('ix_post_status'), table_name='post')
    op.drop_column('post', 'status')

    op.drop_index(op.f('ix_post_moderation_log_user_id'), table_name='post_moderation_log')
    op.drop_index(op.f('ix_post_moderation_log_post_id'), table_name='post_moderation_log')
    op.drop_table('post_moderation_log')
