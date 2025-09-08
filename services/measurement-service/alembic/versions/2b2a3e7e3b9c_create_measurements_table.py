"""create measurements table

Revision ID: 2b2a3e7e3b9c
Revises: 
Create Date: 2023-10-27 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '2b2a3e7e3b9c'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'measurements',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('aquarium_id', sa.Integer(), nullable=False),
        sa.Column('parameter_type', sa.String(), nullable=True),
        sa.Column('value', sa.Float(), nullable=True),
        sa.Column('timestamp', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        schema='measurement'
    )
    op.create_index(op.f('ix_measurements_id'), 'measurements', ['id'], unique=False, schema='measurement')
    op.create_index(op.f('ix_measurements_user_id'), 'measurements', ['user_id'], unique=False, schema='measurement')
    op.create_index(op.f('ix_measurements_aquarium_id'), 'measurements', ['aquarium_id'], unique=False, schema='measurement')
    op.create_index(op.f('ix_measurements_parameter_type'), 'measurements', ['parameter_type'], unique=False, schema='measurement')


def downgrade():
    op.drop_index(op.f('ix_measurements_parameter_type'), table_name='measurements', schema='measurement')
    op.drop_index(op.f('ix_measurements_aquarium_id'), table_name='measurements', schema='measurement')
    op.drop_index(op.f('ix_measurements_user_id'), table_name='measurements', schema='measurement')
    op.drop_index(op.f('ix_measurements_id'), table_name='measurements', schema='measurement')
    op.drop_table('measurements', schema='measurement')
