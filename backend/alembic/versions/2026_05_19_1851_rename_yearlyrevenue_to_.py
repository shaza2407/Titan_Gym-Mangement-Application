"""rename_yearlyRevenue_to_yearlySubscriptionPrice

Revision ID: 592acd824cd1
Revises: 42c5a799f5a8
Create Date: 2026-05-19 18:51:40.937663

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '592acd824cd1'
down_revision: Union[str, Sequence[str], None] = '42c5a799f5a8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
