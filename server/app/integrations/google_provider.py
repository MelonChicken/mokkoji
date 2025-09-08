"""Google Calendar provider implementation

설계 의도:
- Google Calendar API v3 래핑하여 read/write/delta 모든 기능 지원
- 지수 백오프로 rate limit 및 일시적 오류 처리
- RFC 5545 RRULE과 Google 반복 이벤트 매핑

"""
import httpx
import asyncio
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from urllib.parse import urlencode
import logging

from .base import (
    CalendarProvider, ProviderCapabilities, CalendarEventDTO, CalendarDTO,
    SyncResult, ProviderError, RateLimitError, AuthenticationError, SyncCapability
)

logger = logging.getLogger(__name__)

class GoogleCalendarProvider:
    """Google Calendar API 제공자"""
    
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self._http_client: Optional[httpx.AsyncClient] = None
    
    @property
    def name(self) -> str:
        return "google"
    
    @property 
    def capabilities(self) -> ProviderCapabilities:
        return ProviderCapabilities(read=True, write=True, delta=True)
    
    async def _get_client(self) -> httpx.AsyncClient:
        if self._http_client is None:
            self._http_client = httpx.AsyncClient(
                base_url="https://www.googleapis.com/calendar/v3",
                timeout=30.0,
                headers={"User-Agent": "Mokkoji/1.0"}
            )
        return self._http_client
    
    async def _request_with_retry(
        self, 
        method: str, 
        url: str, 
        headers: Dict[str, str],
        max_retries: int = 3,
        **kwargs
    ) -> httpx.Response:
        """지수 백오프로 재시도하는 HTTP 요청"""
        client = await self._get_client()
        
        for attempt in range(max_retries + 1):
            try:
                response = await client.request(method, url, headers=headers, **kwargs)
                
                if response.status_code == 429:  # Rate limit
                    retry_after = int(response.headers.get('Retry-After', 60))
                    if attempt < max_retries:
                        # 지수 백오프 + jitter
                        wait_time = min(2 ** attempt + retry_after, 300)
                        await asyncio.sleep(wait_time)
                        continue
                    raise RateLimitError(self.name, retry_after)
                
                if response.status_code == 401:
                    raise AuthenticationError(self.name, "Invalid or expired token")
                
                if response.status_code >= 500 and attempt < max_retries:
                    # 서버 오류 시 재시도
                    import random
                    jitter = random.uniform(0.1, 0.5)
                    wait_time = (2 ** attempt) + jitter
                    await asyncio.sleep(wait_time)
                    continue
                
                response.raise_for_status()
                return response
                
            except httpx.RequestError as e:
                if attempt < max_retries:
                    wait_time = 2 ** attempt
                    await asyncio.sleep(wait_time)
                    continue
                raise ProviderError(f"Network error: {e}", self.name)
        
        raise ProviderError("Max retries exceeded", self.name)
    
    def _parse_datetime(self, dt_obj: Dict[str, Any]) -> datetime:
        """Google 날짜 객체를 UTC datetime으로 변환"""
        if 'dateTime' in dt_obj:
            # RFC 3339 형식
            dt_str = dt_obj['dateTime']
            return datetime.fromisoformat(dt_str.replace('Z', '+00:00')).astimezone(timezone.utc)
        elif 'date' in dt_obj:
            # 종일 이벤트
            date_str = dt_obj['date'] 
            return datetime.strptime(date_str, '%Y-%m-%d').replace(tzinfo=timezone.utc)
        else:
            raise ValueError("Invalid Google datetime object")
    
    def _format_datetime(self, dt: datetime, all_day: bool = False) -> Dict[str, str]:
        """datetime을 Google API 형식으로 변환"""
        if all_day:
            return {'date': dt.strftime('%Y-%m-%d')}
        else:
            return {'dateTime': dt.isoformat(), 'timeZone': 'UTC'}
    
    def _parse_recurrence(self, recurrence_list: List[str]) -> Optional[str]:
        """Google 반복 규칙을 RRULE 문자열로 변환"""
        if not recurrence_list:
            return None
        
        # Google은 RRULE, EXDATE 등을 배열로 제공
        rrule_lines = [line for line in recurrence_list if line.startswith('RRULE:')]
        return rrule_lines[0] if rrule_lines else None
    
    def _format_recurrence(self, rrule: str) -> List[str]:
        """RRULE을 Google 반복 형식으로 변환"""
        if not rrule or not rrule.startswith('RRULE:'):
            return []
        return [rrule]
    
    def _parse_event(self, event_data: Dict[str, Any]) -> CalendarEventDTO:
        """Google event를 CalendarEventDTO로 변환"""
        start_dt = self._parse_datetime(event_data['start'])
        end_dt = self._parse_datetime(event_data.get('end', event_data['start']))
        
        # 종일 이벤트 판별
        all_day = 'date' in event_data['start']
        
        # 참석자 파싱
        attendees = []
        for attendee in event_data.get('attendees', []):
            attendees.append({
                'email': attendee.get('email'),
                'name': attendee.get('displayName'),
                'status': attendee.get('responseStatus', 'needsAction')
            })
        
        return CalendarEventDTO(
            external_event_id=event_data['id'],
            calendar_id=event_data.get('organizer', {}).get('email', ''),
            title=event_data.get('summary', 'No Title'),
            description=event_data.get('description'),
            start_utc=start_dt,
            end_utc=end_dt,
            all_day=all_day,
            location=event_data.get('location'),
            recurrence_rule=self._parse_recurrence(event_data.get('recurrence', [])),
            attendees=attendees,
            external_updated_at=datetime.fromisoformat(
                event_data['updated'].replace('Z', '+00:00')
            ).astimezone(timezone.utc),
            external_version=event_data.get('etag'),
            deleted=event_data.get('status') == 'cancelled'
        )
    
    async def list_calendars(self, access_token: str) -> List[CalendarDTO]:
        """사용자 캘린더 목록 조회"""
        headers = {'Authorization': f'Bearer {access_token}'}
        
        try:
            response = await self._request_with_retry('GET', '/users/me/calendarList', headers)
            data = response.json()
            
            calendars = []
            for cal_item in data.get('items', []):
                calendars.append(CalendarDTO(
                    external_calendar_id=cal_item['id'],
                    display_name=cal_item.get('summary', 'Untitled'),
                    timezone=cal_item.get('timeZone'),
                    color=cal_item.get('backgroundColor'),
                    access_role=cal_item.get('accessRole'),
                    primary=cal_item.get('primary', False)
                ))
            
            return calendars
            
        except Exception as e:
            logger.error(f"Failed to list Google calendars: {e}")
            raise ProviderError(f"Failed to list calendars: {e}", self.name)
    
    async def fetch_events(
        self,
        access_token: str,
        calendar_id: str, 
        since: datetime,
        until: datetime,
        delta_token: Optional[str] = None,
        updated_min: Optional[datetime] = None
    ) -> SyncResult:
        """이벤트 조회 (증분 동기화 지원)"""
        headers = {'Authorization': f'Bearer {access_token}'}
        
        # 쿼리 파라미터 구성
        params = {
            'maxResults': 2500,
            'singleEvents': 'true',
            'orderBy': 'updated'
        }
        
        if delta_token:
            # 증분 동기화
            params['syncToken'] = delta_token
        else:
            # 윈도우 동기화
            params['timeMin'] = since.isoformat()
            params['timeMax'] = until.isoformat() 
            if updated_min:
                params['updatedMin'] = updated_min.isoformat()
        
        try:
            url = f'/calendars/{calendar_id}/events?' + urlencode(params)
            response = await self._request_with_retry('GET', url, headers)
            data = response.json()
            
            events = []
            for event_data in data.get('items', []):
                try:
                    event = self._parse_event(event_data)
                    events.append(event)
                except Exception as e:
                    logger.warning(f"Failed to parse Google event {event_data.get('id')}: {e}")
                    continue
            
            # 다음 동기화 토큰
            next_sync_token = data.get('nextSyncToken')
            
            # 최신 업데이트 시간
            max_updated = None
            if events:
                max_updated = max(event.external_updated_at for event in events)
            
            return SyncResult(
                events=events,
                next_delta_token=next_sync_token,
                max_updated_at=max_updated,
                has_more=False  # Google은 모든 이벤트를 한 번에 반환
            )
            
        except Exception as e:
            logger.error(f"Failed to fetch Google events: {e}")
            if "Invalid sync token" in str(e):
                # sync token 만료 시 full sync로 재시도
                return await self.fetch_events(access_token, calendar_id, since, until)
            raise ProviderError(f"Failed to fetch events: {e}", self.name)
    
    async def upsert_event(
        self, 
        access_token: str,
        calendar_id: str,
        event: CalendarEventDTO
    ) -> CalendarEventDTO:
        """이벤트 생성/수정"""
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        # Google event 객체 구성
        event_body = {
            'summary': event.title,
            'description': event.description,
            'start': self._format_datetime(event.start_utc, event.all_day),
            'end': self._format_datetime(event.end_utc or event.start_utc, event.all_day),
            'location': event.location,
        }
        
        if event.recurrence_rule:
            event_body['recurrence'] = self._format_recurrence(event.recurrence_rule)
        
        if event.attendees:
            event_body['attendees'] = [
                {
                    'email': att.get('email'),
                    'displayName': att.get('name'),
                    'responseStatus': att.get('status', 'needsAction')
                }
                for att in event.attendees if att.get('email')
            ]
        
        try:
            if event.external_event_id:
                # 기존 이벤트 수정
                url = f'/calendars/{calendar_id}/events/{event.external_event_id}'
                response = await self._request_with_retry('PUT', url, headers, json=event_body)
            else:
                # 새 이벤트 생성
                url = f'/calendars/{calendar_id}/events'
                response = await self._request_with_retry('POST', url, headers, json=event_body)
            
            created_event = response.json()
            return self._parse_event(created_event)
            
        except Exception as e:
            logger.error(f"Failed to upsert Google event: {e}")
            raise ProviderError(f"Failed to upsert event: {e}", self.name)
    
    async def delete_event(
        self,
        access_token: str,
        calendar_id: str, 
        external_event_id: str
    ) -> None:
        """이벤트 삭제"""
        headers = {'Authorization': f'Bearer {access_token}'}
        
        try:
            url = f'/calendars/{calendar_id}/events/{external_event_id}'
            await self._request_with_retry('DELETE', url, headers)
            
        except Exception as e:
            logger.error(f"Failed to delete Google event {external_event_id}: {e}")
            raise ProviderError(f"Failed to delete event: {e}", self.name)
    
    async def close(self):
        """리소스 정리"""
        if self._http_client:
            await self._http_client.aclose()

# Acceptance Criteria:
# - Google Calendar API v3의 모든 CRUD 작업 지원
# - 증분 동기화 (syncToken) 및 윈도우 동기화 지원  
# - Rate limit 및 일시적 오류에 대한 지수 백오프 재시도
# - RRULE과 Google 반복 이벤트 간 양방향 변환
# - UTC 시간 기준으로 모든 datetime 처리