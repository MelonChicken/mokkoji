"""Event and Calendar database models for PostgreSQL

PostgreSQL 스키마에 맞춘 SQLAlchemy 모델 정의
- events 테이블: 실제 레포의 스키마와 호환
- calendars 테이블: 캘린더 정보
- UTC timestamp를 integer로 저장 (Unix timestamp)

"""
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, Text, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import uuid

Base = declarative_base()

class Calendar(Base):
    __tablename__ = 'calendars'

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(UUID(as_uuid=True), nullable=False)  # Add user_id for AI routes
    display_name = Column(String, nullable=False)
    source_platform = Column(String)  # 'google', 'outlook', 'apple', 'local'
    external_calendar_id = Column(String)  # original ID from external provider
    tz = Column(String, nullable=False, default='Asia/Seoul')
    created_at = Column(Integer, nullable=False, default=lambda: int(datetime.now(timezone.utc).timestamp()))
    updated_at = Column(Integer, nullable=False, default=lambda: int(datetime.now(timezone.utc).timestamp()))

    # Relationships
    events = relationship("Event", back_populates="calendar", cascade="all, delete-orphan")

class Event(Base):
    __tablename__ = 'events'

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    calendar_id = Column(String, ForeignKey('calendars.id', ondelete='CASCADE'), nullable=False)
    external_event_id = Column(String)  # original ID from external provider
    title = Column(String, nullable=False)
    description = Column(Text)
    start_utc = Column(Integer, nullable=False)  # Unix timestamp in UTC
    end_utc = Column(Integer)  # Unix timestamp in UTC
    all_day = Column(Boolean, nullable=False, default=False)  # 1 for all-day events
    location = Column(Text)
    recurrence_rule = Column(Text)  # RRULE string (RFC 5545 format)
    external_updated_at = Column(Integer)  # last update timestamp from external source
    external_version = Column(Text)  # version/etag from external source
    deleted = Column(Boolean, nullable=False, default=False)  # soft delete flag
    last_modified_local = Column(Integer, nullable=False, default=lambda: int(datetime.now(timezone.utc).timestamp()))
    sync_status = Column(String, nullable=False, default='synced')  # 'synced', 'pending', 'failed'

    # AI 서비스 호환성을 위한 추가 필드
    external_calendar_id = Column(String)  # 외부 캘린더 ID

    # Relationships
    calendar = relationship("Calendar", back_populates="events")
    overrides = relationship("EventOverride", back_populates="event", cascade="all, delete-orphan")
    attendees = relationship("Attendee", back_populates="event", cascade="all, delete-orphan")

class EventOverride(Base):
    __tablename__ = 'event_overrides'

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    event_id = Column(String, ForeignKey('events.id', ondelete='CASCADE'), nullable=False)
    occurrence_date = Column(String, nullable=False)  # YYYY-MM-DD format for the original occurrence
    override_type = Column(String, nullable=False, default='modification')  # 'modification', 'deletion'
    title = Column(Text)  # override title (null = use original)
    description = Column(Text)  # override description (null = use original)
    start_utc = Column(Integer)  # override start time (null = use original)
    end_utc = Column(Integer)  # override end time (null = use original)
    location = Column(Text)  # override location (null = use original)
    created_at = Column(Integer, nullable=False, default=lambda: int(datetime.now(timezone.utc).timestamp()))

    # Relationships
    event = relationship("Event", back_populates="overrides")

class Attendee(Base):
    __tablename__ = 'attendees'

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    event_id = Column(String, ForeignKey('events.id', ondelete='CASCADE'), nullable=False)
    email = Column(Text)
    display_name = Column(Text)
    response_status = Column(String, default='needsAction')  # 'accepted', 'declined', 'tentative', 'needsAction'
    is_organizer = Column(Boolean, nullable=False, default=False)
    created_at = Column(Integer, nullable=False, default=lambda: int(datetime.now(timezone.utc).timestamp()))

    # Relationships
    event = relationship("Event", back_populates="attendees")

# Indexes for performance optimization (matching schema.drift)
Index('idx_events_calendar_start', Event.calendar_id, Event.start_utc)
Index('idx_events_deleted', Event.deleted)
Index('idx_events_sync_status', Event.sync_status)
Index('idx_events_recurrence', Event.recurrence_rule)
Index('idx_event_overrides_event_date', EventOverride.event_id, EventOverride.occurrence_date)
Index('idx_attendees_event', Attendee.event_id)