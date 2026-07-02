"""retention offer manual update

Revision ID: 26bdeceb2823
Revises: 6a5cb66c0061
Create Date: 2026-07-02 18:45:53.866595

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql



# revision identifiers, used by Alembic.
revision: str = '26bdeceb2823'
down_revision: Union[str, Sequence[str], None] = '6a5cb66c0061'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    bind = op.get_bind()

    # rename existing mismatched labels to match the model
    bind.execute(sa.text("ALTER TYPE offertype RENAME VALUE 'supplement' TO 'supplements'"))
    bind.execute(sa.text("ALTER TYPE offertype RENAME VALUE 'free_session' TO 'free_sessions'"))

    # now cast the column — type already exists with correct values, no CREATE TYPE needed
    op.alter_column(
        'retention_offers', 'offer_type',
        existing_type=sa.VARCHAR(),
        type_=postgresql.ENUM(
            'discount', 'supplements', 'free_sessions', 'membership_upgrade',
            name='offertype'
        ),
        existing_nullable=False,
        postgresql_using='offer_type::offertype',
    )

def downgrade() -> None:
    """Downgrade schema."""
    pass
