"""Add sync schema for external calendar integration

설계 의도:
- sync_state: 각 외부 캘린더별 증분 동기화 상태 관리 (delta_token, updated_min)
- events 확장: 외부 캘린더 메타데이터 및 버전 관리로 충돌 해결
- 인덱스 최적화: 동기화 성능과 범위 쿼리 최적화

Revision ID: 001
Revises: 
Create Date: 2025-01-20 10:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '001'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    # Create sync_state table for tracking external calendar sync status
    op.create_table(
        'sync_state',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('connection_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('external_calendar_id', sa.Text(), nullable=False),
        sa.Column('delta_token', sa.Text(), nullable=True),
        sa.Column('updated_min', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_window_start', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_window_end', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()),
        sa.UniqueConstraint('user_id', 'connection_id', 'external_calendar_id', name='uq_sync_state_user_conn_cal'),
        sa.ForeignKeyConstraint(['connection_id'], ['external_connections.id'], ondelete='CASCADE'),
        sa.Index('idx_sync_state_user_id', 'user_id'),
        sa.Index('idx_sync_state_connection_id', 'connection_id'),
    )

    # Extend events table with external calendar metadata
    op.add_column('events', sa.Column('external_calendar_id', sa.Text(), nullable=True))
    op.add_column('events', sa.Column('external_updated_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('events', sa.Column('external_version', sa.Text(), nullable=True))  # etag, version
    op.add_column('events', sa.Column('deleted', sa.Boolean(), nullable=False, server_default='false'))

    # Create indexes for sync performance
    op.create_index('idx_events_external_cal_id', 'events', ['external_calendar_id'])
    op.create_index('idx_events_external_updated_at', 'events', ['external_updated_at'])
    op.create_index('idx_events_deleted', 'events', ['deleted'])
    op.create_index('idx_events_sync_lookup', 'events', ['user_id', 'source_platform', 'external_calendar_id', 'external_event_id'])

    # Assume external_connections table exists, add sync-related columns if missing
    try:
        op.add_column('external_connections', sa.Column('sync_enabled', sa.Boolean(), nullable=False, server_default='true'))
        op.add_column('external_connections', sa.Column('last_sync_at', sa.DateTime(timezone=True), nullable=True))
        op.add_column('external_connections', sa.Column('sync_status', sa.Text(), nullable=False, server_default='idle'))
        op.add_column('external_connections', sa.Column('last_error', sa.Text(), nullable=True))
    except:
        # Columns may already exist
        pass

def downgrade():
    # Drop indexes
    op.drop_index('idx_events_sync_lookup')
    op.drop_index('idx_events_deleted') 
    op.drop_index('idx_events_external_updated_at')
    op.drop_index('idx_events_external_cal_id')

    # Remove added columns from events
    op.drop_column('events', 'deleted')
    op.drop_column('events', 'external_version')
    op.drop_column('events', 'external_updated_at')
    op.drop_column('events', 'external_calendar_id')

    # Drop sync_state table
    op.drop_table('sync_state')

    # Remove sync columns from external_connections (optional)
    try:
        op.drop_column('external_connections', 'last_error')
        op.drop_column('external_connections', 'sync_status')
        op.drop_column('external_connections', 'last_sync_at')
        op.drop_column('external_connections', 'sync_enabled')
    except:
        pass

# Acceptance Criteria:
# - sync_state table tracks delta tokens and window bounds per external calendar
# - events table extended with external metadata for conflict resolution
# - Indexes support efficient range queries and sync lookups
# - Migration is reversible and handles existing data gracefully