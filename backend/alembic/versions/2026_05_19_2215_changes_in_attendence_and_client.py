"""changes in attendence and client

Revision ID: 16d6eb4e47bc
Revises: 592acd824cd1
Create Date: 2026-05-19 22:15:37.758957

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '16d6eb4e47bc'
down_revision: Union[str, Sequence[str], None] = '592acd824cd1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
