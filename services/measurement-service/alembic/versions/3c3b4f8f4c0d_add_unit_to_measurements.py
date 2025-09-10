"""add unit to measurements

Revision ID: 3c3b4f8f4c0d
Revises: 2b2a3e7e3b9c
Create Date: 2023-11-16 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '3c3b4f8f4c0d'
down_revision = '2b2a3e7e3b9c'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        'measurements',
        sa.Column('unit', sa.String(), nullable=True),
        schema='measurement'
    )


def downgrade():
    op.drop_column('measurements', 'unit', schema='measurement')
