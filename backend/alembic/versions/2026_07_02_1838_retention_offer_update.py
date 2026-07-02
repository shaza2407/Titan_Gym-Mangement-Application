"""retention offer update

Revision ID: 6a5cb66c0061
Revises: 6e1d33d80842
Create Date: 2026-07-02 18:38:17.795352

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '6a5cb66c0061'
down_revision: Union[str, Sequence[str], None] = '6e1d33d80842'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


offertype_enum = postgresql.ENUM(
    'discount', 'supplements', 'free_sessions', 'membership_upgrade',
    name='offertype'
)


def upgrade() -> None:
    """Upgrade schema."""

    offertype_enum.create(op.get_bind(), checkfirst=True)

    # 2. cast the column, telling Postgres explicitly how
    op.alter_column(
        'retention_offers', 'offer_type',
        existing_type=sa.VARCHAR(),
        type_=offertype_enum,
        existing_nullable=False,
        postgresql_using='offer_type::offertype',
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.alter_column(
        'retention_offers', 'offer_type',
        existing_type=offertype_enum,
        type_=sa.VARCHAR(),
        existing_nullable=False,
        postgresql_using='offer_type::text',  
    )

    # drop the enum type on downgrade so the schema fully reverts
    offertype_enum.drop(op.get_bind(), checkfirst=True)