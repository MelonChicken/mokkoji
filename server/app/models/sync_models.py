"""동기화 관련 데이터베이스 모델

외부 캘린더 연결 및 동기화 상태 관리
- external_connections: 외부 캘린더 서비스 연결 정보
- sync_state: 각 캘린더별 동기화 상태

"""
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, Text, DateTime, ForeignKey, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid

Base = declarative_base()

class ExternalConnection(Base):
    __tablename__ = 'external_connections'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    platform_type = Column(String, nullable=False)  # 'google', 'outlook', 'apple'
    access_token_encrypted = Column(Text, nullable=False)  # 암호화된 액세스 토큰
    refresh_token_encrypted = Column(Text)  # 암호화된 리프레시 토큰
    token_expires_at = Column(DateTime(timezone=True))
    sync_enabled = Column(Boolean, nullable=False, default=True)
    last_sync_at = Column(DateTime(timezone=True))
    sync_status = Column(String, nullable=False, default='idle')  # 'idle', 'syncing', 'error'
    last_error = Column(Text)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    sync_states = relationship("SyncState", back_populates="connection", cascade="all, delete-orphan")

class SyncState(Base):
    __tablename__ = 'sync_state'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    connection_id = Column(UUID(as_uuid=True), ForeignKey('external_connections.id', ondelete='CASCADE'), nullable=False)
    external_calendar_id = Column(Text, nullable=False)
    delta_token = Column(Text)  # Google Calendar delta token
    updated_min = Column(DateTime(timezone=True))  # 마지막 업데이트 시간
    last_window_start = Column(DateTime(timezone=True))
    last_window_end = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    connection = relationship("ExternalConnection", back_populates="sync_states")

    # Constraints
    __table_args__ = (
        UniqueConstraint('user_id', 'connection_id', 'external_calendar_id', name='uq_sync_state_user_conn_cal'),
        Index('idx_sync_state_user_id', 'user_id'),
        Index('idx_sync_state_connection_id', 'connection_id'),
    )