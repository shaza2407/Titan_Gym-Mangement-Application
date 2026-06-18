"""rename_yearlyRevenue_to_yearlySubscription

Revision ID: 42c5a799f5a8
Revises: 1244ebaa0fce
Create Date: 2026-05-19 18:37:52.980236

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '42c5a799f5a8'
down_revision: Union[str, Sequence[str], None] = '1244ebaa0fce'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade():
    op.alter_column(
        'gyms',
        'yearlyRevenue',              # old name in DB
        new_column_name='yearlySubscriptionPrice'  # new name
    )

def downgrade():
    op.alter_column(
        'gyms',
        'yearlyRevenue',              # old name in DB
        new_column_name='yearlySubscriptionPrice'  # new name
    )