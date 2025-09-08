"""Base calendar provider interface and DTOs

설계 의도:
- Protocol 기반 인터페이스로 다양한 캘린더 제공자 지원
- ProviderCapabilities로 각 제공자의 read/write/delta 지원 여부 명시
- CalendarEventDTO로 제공자 중립적인 데이터 교환

"""
from typing import Protocol, Optional, List, Tuple, Dict, Any
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum

class SyncCapability(Enum):
    READ = "read"
    WRITE = "write" 
    DELTA = "delta"  # incremental sync support

@dataclass
class ProviderCapabilities:
    """각 캘린더 제공자의 지원 기능 정의"""
    read: bool = False
    write: bool = False
    delta: bool = False  # 증분 동기화 지원 여부
    
    def supports(self, capability: SyncCapability) -> bool:
        return getattr(self, capability.value, False)

@dataclass
class CalendarEventDTO:
    """제공자 중립적인 캘린더 이벤트 DTO (모든 시간은 UTC)"""
    external_event_id: str
    calendar_id: str
    title: str
    description: Optional[str] = None
    start_utc: datetime = field(default_factory=datetime.utcnow)
    end_utc: Optional[datetime] = None
    all_day: bool = False
    location: Optional[str] = None
    recurrence_rule: Optional[str] = None  # RRULE format
    attendees: List[Dict[str, Any]] = field(default_factory=list)
    external_updated_at: datetime = field(default_factory=datetime.utcnow)
    external_version: Optional[str] = None  # etag, version string
    deleted: bool = False

    def to_dict(self) -> Dict[str, Any]:
        return {
            'external_event_id': self.external_event_id,
            'calendar_id': self.calendar_id,
            'title': self.title,
            'description': self.description,
            'start_utc': self.start_utc.isoformat() if self.start_utc else None,
            'end_utc': self.end_utc.isoformat() if self.end_utc else None,
            'all_day': self.all_day,
            'location': self.location,
            'recurrence_rule': self.recurrence_rule,
            'attendees': self.attendees,
            'external_updated_at': self.external_updated_at.isoformat(),
            'external_version': self.external_version,
            'deleted': self.deleted
        }

@dataclass 
class CalendarDTO:
    """외부 캘린더 메타데이터"""
    external_calendar_id: str
    display_name: str
    timezone: Optional[str] = None
    color: Optional[str] = None
    access_role: Optional[str] = None  # owner, reader, writer
    primary: bool = False

@dataclass
class SyncResult:
    """동기화 결과"""
    events: List[CalendarEventDTO]
    next_delta_token: Optional[str] = None
    max_updated_at: Optional[datetime] = None
    has_more: bool = False
    error: Optional[str] = None

class ProviderError(Exception):
    """제공자 관련 오류 기본 클래스"""
    def __init__(self, message: str, provider: str, error_code: Optional[str] = None):
        self.provider = provider
        self.error_code = error_code
        super().__init__(f"{provider}: {message}")

class RateLimitError(ProviderError):
    """API 요청 제한 오류"""
    def __init__(self, provider: str, retry_after: Optional[int] = None):
        self.retry_after = retry_after
        super().__init__(f"Rate limit exceeded. Retry after {retry_after}s", provider, "RATE_LIMIT")

class AuthenticationError(ProviderError):
    """인증 오류"""
    def __init__(self, provider: str, message: str = "Authentication failed"):
        super().__init__(message, provider, "AUTH_ERROR")

class CalendarProvider(Protocol):
    """캘린더 제공자 인터페이스"""
    
    @property
    def name(self) -> str:
        """제공자 이름 (google, naver, kakao)"""
        ...
    
    @property
    def capabilities(self) -> ProviderCapabilities:
        """지원 기능"""
        ...
    
    async def list_calendars(self, access_token: str) -> List[CalendarDTO]:
        """사용자의 캘린더 목록 조회"""
        ...
    
    async def fetch_events(
        self,
        access_token: str,
        calendar_id: str,
        since: datetime,
        until: datetime,
        delta_token: Optional[str] = None,
        updated_min: Optional[datetime] = None
    ) -> SyncResult:
        """
        이벤트 조회 (증분 동기화 지원)
        
        Args:
            access_token: OAuth 토큰
            calendar_id: 대상 캘린더 ID
            since: 조회 시작 시간 (UTC)
            until: 조회 종료 시간 (UTC)
            delta_token: 증분 동기화 토큰 (지원 시)
            updated_min: 최종 업데이트 시간 기준 (증분용)
            
        Returns:
            SyncResult with events and next sync tokens
        """
        ...
    
    async def upsert_event(
        self,
        access_token: str,
        calendar_id: str,
        event: CalendarEventDTO
    ) -> CalendarEventDTO:
        """이벤트 생성/수정"""
        ...
    
    async def delete_event(
        self,
        access_token: str, 
        calendar_id: str,
        external_event_id: str
    ) -> None:
        """이벤트 삭제"""
        ...

# Acceptance Criteria:
# - Protocol 기반으로 다양한 제공자 구현 가능
# - DTO는 제공자 중립적이며 UTC 시간 사용
# - 오류 클래스로 타입별 예외 처리 지원
# - 증분 동기화와 윈도우 동기화 모두 지원