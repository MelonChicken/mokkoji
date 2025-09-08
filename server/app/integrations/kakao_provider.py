"""Kakao Calendar provider placeholder implementation

설계 의도:
- 카카오 캘린더는 현재 공식 API 없음, OS/iCal 연동 경로 추천
- 서버 측은 인터페이스만 구현하여 향후 확장 대비
- 적절한 오류 메시지로 사용자에게 대안 안내

"""
from typing import List, Optional
from datetime import datetime
import logging

from .base import (
    CalendarProvider, ProviderCapabilities, CalendarEventDTO, CalendarDTO,
    SyncResult, ProviderError
)

logger = logging.getLogger(__name__)

class KakaoCalendarProvider:
    """카카오 캘린더 제공자 (placeholder)"""
    
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
    
    @property
    def name(self) -> str:
        return "kakao"
    
    @property
    def capabilities(self) -> ProviderCapabilities:
        # 현재는 모든 기능 미지원
        return ProviderCapabilities(read=False, write=False, delta=False)
    
    async def list_calendars(self, access_token: str) -> List[CalendarDTO]:
        """카카오 캘린더 목록 - 현재 미지원"""
        raise ProviderError(
            "Kakao Calendar API is not available. "
            "Please use device calendar app or export/import iCal files.",
            self.name
        )
    
    async def fetch_events(
        self,
        access_token: str,
        calendar_id: str,
        since: datetime,
        until: datetime,
        delta_token: Optional[str] = None,
        updated_min: Optional[datetime] = None
    ) -> SyncResult:
        """카카오 이벤트 조회 - 현재 미지원"""
        logger.warning("Attempted to fetch Kakao calendar events - not supported")
        raise ProviderError(
            "Kakao Calendar reading is not supported. "
            "Consider using device calendar sync or manual iCal import.",
            self.name
        )
    
    async def upsert_event(
        self,
        access_token: str,
        calendar_id: str,
        event: CalendarEventDTO
    ) -> CalendarEventDTO:
        """카카오 이벤트 생성/수정 - 현재 미지원"""
        logger.warning(f"Attempted to create Kakao event: {event.title}")
        raise ProviderError(
            "Kakao Calendar writing is not supported. "
            "Event will be saved locally only. You can manually add it to Kakao Calendar app.",
            self.name
        )
    
    async def delete_event(
        self,
        access_token: str,
        calendar_id: str,
        external_event_id: str
    ) -> None:
        """카카오 이벤트 삭제 - 현재 미지원"""
        logger.warning(f"Attempted to delete Kakao event: {external_event_id}")
        raise ProviderError(
            "Kakao Calendar deletion is not supported. "
            "Event will be marked as deleted locally. Please manually remove from Kakao Calendar app.",
            self.name
        )
    
    async def close(self):
        """리소스 정리 - 현재 상태에서는 작업 없음"""
        pass

# Acceptance Criteria:
# - 모든 메서드가 적절한 오류 메시지와 함께 ProviderError 발생
# - 사용자에게 대안 방법 (OS 캘린더, iCal 파일) 안내
# - 향후 카카오 API 지원 시 쉽게 확장 가능한 구조
# - 로깅으로 미지원 기능 사용 시도 추적