"""changing notification  table 

Revision ID: 0dbb297c18bd
Revises: 6d8f32aa7119
Create Date: 2026-06-26 04:27:56.499048

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0dbb297c18bd'
down_revision: Union[str, Sequence[str], None] = '6d8f32aa7119'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# ✅ fixed — drop the old UUID column and recreate as serial Integer
def upgrade():
    # 1 — drop the old UUID primary key
    op.drop_constraint('notifications_pkey', 'notifications', type_='primary')
    op.drop_column('notifications', 'id')

    # 2 — add new auto-increment integer id
    op.add_column('notifications',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False)
    )
    op.execute("CREATE SEQUENCE IF NOT EXISTS notifications_id_seq")
    op.execute("ALTER TABLE notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq')")
    op.execute("SELECT setval('notifications_id_seq', COALESCE(MAX(id), 0) + 1) FROM notifications")

    # 3 — set as primary key
    op.create_primary_key('notifications_pkey', 'notifications', ['id'])


def downgrade():
    op.drop_constraint('notifications_pkey', 'notifications', type_='primary')
    op.drop_column('notifications', 'id')
    op.add_column('notifications',
        sa.Column('id', sa.UUID(), nullable=False)
    )
    op.create_primary_key('notifications_pkey', 'notifications', ['id'])