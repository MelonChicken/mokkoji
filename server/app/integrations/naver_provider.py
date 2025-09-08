"""Naver Calendar provider implementation

설계 의도:
- 네이버는 createSchedule.json API로 ICS 문자열 전송 방식 지원
- 읽기는 기본 미지원, 옵션으로 사용자 제공 ICS URL 파싱
- 같은 UID 재전송으로 수정 처리, 삭제는 미지원

"""
import httpx
import asyncio
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
import logging
import re
from io import StringIO

from .base import (
    CalendarProvider, ProviderCapabilities, CalendarEventDTO, CalendarDTO,
    SyncResult, ProviderError, RateLimitError, AuthenticationError
)

logger = logging.getLogger(__name__)

class NaverCalendarProvider:
    """네이버 캘린더 API 제공자"""
    
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self._http_client: Optional[httpx.AsyncClient] = None
    
    @property
    def name(self) -> str:
        return "naver"
    
    @property
    def capabilities(self) -> ProviderCapabilities:
        # 기본적으로는 쓰기만 지원, 옵션으로 ICS URL 읽기 가능
        return ProviderCapabilities(read=False, write=True, delta=False)
    
    async def _get_client(self) -> httpx.AsyncClient:
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(
                timeout=30.0,
                headers={"User-Agent": "Mokkoji/1.0"}
            )
        return self._http_client
    
    def _generate_ics_content(self, event: CalendarEventDTO) -> str:
        """CalendarEventDTO를 ICS 형식으로 변환"""
        ics_lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//Mokkoji//Calendar//KR",
            "CALSCALE:GREGORIAN",
            "METHOD:REQUEST",
            "BEGIN:VEVENT"
        ]
        
        # UID 생성 (고유 식별자)
        uid = event.external_event_id or f"mokkoji-{hash(event.title + str(event.start_utc))}"
        ics_lines.append(f"UID:{uid}")
        
        # 기본 정보
        ics_lines.append(f"SUMMARY:{self._escape_ics_text(event.title)}")
        
        if event.description:
            ics_lines.append(f"DESCRIPTION:{self._escape_ics_text(event.description)}")
        
        if event.location:
            ics_lines.append(f"LOCATION:{self._escape_ics_text(event.location)}")
        
        # 시간 설정
        if event.all_day:
            ics_lines.append(f"DTSTART;VALUE=DATE:{event.start_utc.strftime('%Y%m%d')}")
            end_date = event.end_utc or event.start_utc
            ics_lines.append(f"DTEND;VALUE=DATE:{end_date.strftime('%Y%m%d')}")
        else:
            ics_lines.append(f"DTSTART:{event.start_utc.strftime('%Y%m%dT%H%M%SZ')}")
            end_time = event.end_utc or event.start_utc
            ics_lines.append(f"DTEND:{end_time.strftime('%Y%m%dT%H%M%SZ')}")
        
        # 반복 규칙
        if event.recurrence_rule:
            ics_lines.append(event.recurrence_rule)
        
        # 참석자
        for attendee in event.attendees:
            if attendee.get('email'):
                name = attendee.get('name', '')
                email = attendee['email']
                status = attendee.get('status', 'NEEDS-ACTION').upper()
                ics_lines.append(f"ATTENDEE;CN={name};PARTSTAT={status}:MAILTO:{email}")
        
        # 메타데이터
        ics_lines.append(f"DTSTAMP:{datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}")
        ics_lines.append("STATUS:CONFIRMED")
        ics_lines.append("TRANSP:OPAQUE")
        
        ics_lines.extend([
            "END:VEVENT",
            "END:VCALENDAR"
        ])
        
        return "\r\n".join(ics_lines)
    
    def _escape_ics_text(self, text: str) -> str:
        """ICS 텍스트 이스케이프"""
        if not text:
            return ""
        return text.replace('\\', '\\\\').replace(',', '\\,').replace(';', '\\;').replace('\n', '\\n')
    
    def _parse_ics_datetime(self, dt_str: str, all_day: bool = False) -> datetime:
        """ICS datetime 문자열을 UTC datetime으로 파싱"""
        if all_day:
            return datetime.strptime(dt_str, '%Y%m%d').replace(tzinfo=timezone.utc)
        
        if dt_str.endswith('Z'):
            return datetime.strptime(dt_str, '%Y%m%dT%H%M%SZ').replace(tzinfo=timezone.utc)
        else:
            # Local time assumed
            dt = datetime.strptime(dt_str, '%Y%m%dT%H%M%S')
            return dt.replace(tzinfo=timezone.utc)  # Assume UTC for simplicity
    
    def _parse_ics_content(self, ics_content: str) -> List[CalendarEventDTO]:
        """ICS 컨텐츠를 파싱하여 이벤트 목록 반환"""
        events = []
        lines = ics_content.replace('\r\n', '\n').split('\n')
        
        current_event = {}
        in_event = False
        
        for line in lines:
            line = line.strip()
            
            if line == 'BEGIN:VEVENT':
                in_event = True
                current_event = {}
                continue
            elif line == 'END:VEVENT':
                if in_event and current_event:
                    try:
                        event = self._parse_ics_event(current_event)
                        events.append(event)
                    except Exception as e:
                        logger.warning(f"Failed to parse ICS event: {e}")
                in_event = False
                continue
            
            if not in_event:
                continue
            
            # 속성 파싱
            if ':' in line:
                key_part, value = line.split(':', 1)
                key = key_part.split(';')[0]  # 파라미터 제거
                current_event[key] = value
        
        return events
    
    def _parse_ics_event(self, event_data: Dict[str, str]) -> CalendarEventDTO:
        """ICS 이벤트 데이터를 CalendarEventDTO로 변환"""
        uid = event_data.get('UID', '')
        title = self._unescape_ics_text(event_data.get('SUMMARY', 'No Title'))
        description = self._unescape_ics_text(event_data.get('DESCRIPTION', ''))
        location = self._unescape_ics_text(event_data.get('LOCATION', ''))
        
        # 시간 파싱
        dtstart = event_data.get('DTSTART', '')
        dtend = event_data.get('DTEND', '')
        
        all_day = 'VALUE=DATE' in dtstart
        start_utc = self._parse_ics_datetime(dtstart.split(':')[-1], all_day)
        end_utc = self._parse_ics_datetime(dtend.split(':')[-1], all_day) if dtend else start_utc
        
        # 업데이트 시간
        dtstamp = event_data.get('DTSTAMP', '')
        updated_at = self._parse_ics_datetime(dtstamp) if dtstamp else datetime.utcnow()
        
        return CalendarEventDTO(
            external_event_id=uid,
            calendar_id='naver-default',
            title=title,
            description=description or None,
            start_utc=start_utc,
            end_utc=end_utc,
            all_day=all_day,
            location=location or None,
            recurrence_rule=event_data.get('RRULE'),
            attendees=[],  # ICS 파싱에서는 단순화
            external_updated_at=updated_at,
            external_version=None
        )
    
    def _unescape_ics_text(self, text: str) -> str:
        """ICS 텍스트 언이스케이프"""
        if not text:
            return ""
        return text.replace('\\n', '\n').replace('\\;', ';').replace('\\,', ',').replace('\\\\', '\\')
    
    async def list_calendars(self, access_token: str) -> List[CalendarDTO]:
        """네이버 캘린더 목록 (기본 캘린더 하나만 반환)"""
        return [CalendarDTO(
            external_calendar_id="naver-default",
            display_name="네이버 캘린더",
            timezone="Asia/Seoul",
            primary=True
        )]
    
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
        이벤트 조회 - 네이버는 기본적으로 읽기 미지원
        옵션: calendar_id가 ICS URL이면 해당 URL에서 이벤트 파싱
        """
        if not calendar_id.startswith('http'):
            # 일반 네이버 캘린더는 읽기 미지원
            raise ProviderError("Naver calendar read not supported. Use ICS URL if available.", self.name)
        
        # ICS URL에서 읽기 시도
        try:
            client = await self._get_client()
            response = await client.get(calendar_id)
            response.raise_for_status()
            
            ics_content = response.text
            events = self._parse_ics_content(ics_content)
            
            # 시간 범위 필터링
            filtered_events = [
                event for event in events
                if since <= event.start_utc < until
            ]
            
            return SyncResult(
                events=filtered_events,
                next_delta_token=None,  # 증분 동기화 미지원
                max_updated_at=max((e.external_updated_at for e in filtered_events), default=None)
            )
            
        except Exception as e:
            logger.error(f"Failed to fetch Naver ICS events: {e}")
            raise ProviderError(f"Failed to fetch ICS events: {e}", self.name)
    
    async def upsert_event(
        self,
        access_token: str,
        calendar_id: str,
        event: CalendarEventDTO
    ) -> CalendarEventDTO:
        """ICS 형식으로 이벤트 생성/수정"""
        client = await self._get_client()
        
        # ICS 컨텐츠 생성
        ics_content = self._generate_ics_content(event)
        
        # 네이버 createSchedule API 호출
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        
        data = {
            'calendarId': 'defaultCalendarId',  # 네이버 기본값
            'scheduleIcalString': ics_content
        }
        
        try:
            response = await client.post(
                'https://openapi.naver.com/calendar/createSchedule.json',
                headers=headers,
                data=data
            )
            
            if response.status_code == 401:
                raise AuthenticationError(self.name)
            elif response.status_code == 429:
                raise RateLimitError(self.name)
            
            response.raise_for_status()
            
            # 네이버 응답에서 이벤트 ID 추출 (있다면)
            result = response.json()
            external_id = result.get('result', {}).get('id') or event.external_event_id
            
            # 업데이트된 이벤트 정보 반환
            return CalendarEventDTO(
                external_event_id=external_id,
                calendar_id=event.calendar_id,
                title=event.title,
                description=event.description,
                start_utc=event.start_utc,
                end_utc=event.end_utc,
                all_day=event.all_day,
                location=event.location,
                recurrence_rule=event.recurrence_rule,
                attendees=event.attendees,
                external_updated_at=datetime.utcnow(),
                external_version=None
            )
            
        except Exception as e:
            logger.error(f"Failed to upsert Naver event: {e}")
            raise ProviderError(f"Failed to create Naver schedule: {e}", self.name)
    
    async def delete_event(
        self,
        access_token: str,
        calendar_id: str,
        external_event_id: str
    ) -> None:
        """네이버 이벤트 삭제 - 미지원"""
        raise ProviderError(
            "Naver calendar delete not supported. Event will be marked as deleted locally.",
            self.name
        )
    
    async def close(self):
        """리소스 정리"""
        if self._http_client:
            await self._http_client.aclose()

# Acceptance Criteria:
# - ICS 형식으로 네이버 캘린더에 이벤트 생성/수정 가능
# - 같은 UID 재전송으로 이벤트 수정 처리
# - 옵션으로 ICS URL 제공 시 읽기 전용 이벤트 파싱 지원
# - 삭제 미지원 시 적절한 오류 메시지와 로컬 마킹 안내
# - UTC 시간 기준으로 모든 datetime 처리