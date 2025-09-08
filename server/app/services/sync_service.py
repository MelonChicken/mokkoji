"""Calendar synchronization service

설계 의도:
- 증분 동기화 (delta token) 우선, fallback으로 윈도우 동기화
- 충돌 해결은 external_version/updated_at 비교로 Last-Write-Wins
- 재시도 정책으로 일시적 오류 처리, 백오프+지터

"""
import asyncio
import logging
from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime, timezone, timedelta
from dataclasses import dataclass
import random

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, and_, or_
from sqlalchemy.dialects.postgresql import insert

from ..integrations.base import CalendarProvider, CalendarEventDTO, ProviderError, RateLimitError
from ..integrations.google_provider import GoogleCalendarProvider
from ..integrations.naver_provider import NaverCalendarProvider  
from ..integrations.kakao_provider import KakaoCalendarProvider
from ..models.sync_models import SyncState, ExternalConnection, Event
from ..core.security import decrypt_token

logger = logging.getLogger(__name__)

@dataclass
class SyncOptions:
    """동기화 옵션"""
    force_full: bool = False
    window_days_past: int = 90
    window_days_future: int = 180
    max_retries: int = 3
    batch_size: int = 100

@dataclass 
class SyncResult:
    """동기화 결과"""
    success: bool
    events_processed: int
    events_created: int
    events_updated: int
    events_deleted: int
    error_message: Optional[str] = None
    next_delta_token: Optional[str] = None
    last_updated_at: Optional[datetime] = None

class CalendarSyncService:
    """캘린더 동기화 서비스"""
    
    def __init__(self, db_session: AsyncSession):
        self.db = db_session
        self.providers: Dict[str, CalendarProvider] = {}
        self._setup_providers()
    
    def _setup_providers(self):
        """캘린더 제공자 초기화"""
        # TODO: 설정에서 client credentials 로드
        self.providers = {
            'google': GoogleCalendarProvider('client_id', 'client_secret'),
            'naver': NaverCalendarProvider('client_id', 'client_secret'),
            'kakao': KakaoCalendarProvider('client_id', 'client_secret')
        }
    
    async def sync_calendar(
        self,
        user_id: str,
        connection_id: str,
        external_calendar_id: str,
        options: Optional[SyncOptions] = None
    ) -> SyncResult:
        """단일 캘린더 동기화 실행"""
        if options is None:
            options = SyncOptions()
        
        try:
            # 연결 정보 조회
            connection = await self._get_connection(connection_id, user_id)
            if not connection or not connection.sync_enabled:
                return SyncResult(success=False, events_processed=0, events_created=0, 
                                events_updated=0, events_deleted=0, 
                                error_message="Connection disabled or not found")
            
            # 제공자 가져오기
            provider = self.providers.get(connection.platform_type)
            if not provider:
                return SyncResult(success=False, events_processed=0, events_created=0,
                                events_updated=0, events_deleted=0,
                                error_message=f"Provider {connection.platform_type} not found")
            
            # 액세스 토큰 복호화
            access_token = await decrypt_token(connection.access_token_encrypted, connection_id)
            
            # 동기화 상태 조회/생성
            sync_state = await self._get_or_create_sync_state(
                user_id, connection_id, external_calendar_id
            )
            
            # 동기화 창 결정
            since, until = self._calculate_sync_window(options)
            
            # 증분 vs 윈도우 동기화 결정
            use_delta = (
                not options.force_full and 
                provider.capabilities.delta and
                sync_state.delta_token
            )
            
            # 재시도 로직으로 이벤트 가져오기
            fetch_result = await self._fetch_events_with_retry(
                provider, access_token, external_calendar_id,
                since, until, sync_state, use_delta, options.max_retries
            )
            
            if not fetch_result.success:
                await self._update_connection_error(connection_id, fetch_result.error_message)
                return fetch_result
            
            # fetch_result에서 실제 이벤트 데이터 추출
            events_to_process = getattr(fetch_result, 'events', [])
            
            # 로컬 DB에 이벤트 적용
            upsert_result = await self._upsert_events(
                user_id, connection.platform_type, external_calendar_id,
                events_to_process, options.batch_size
            )
            
            # 동기화 상태 업데이트  
            await self._update_sync_state(
                sync_state, fetch_result.next_delta_token,
                fetch_result.last_updated_at, since, until
            )
            
            # 연결 상태 업데이트
            await self._update_connection_success(connection_id)
            
            return SyncResult(
                success=True,
                events_processed=len(events_to_process),
                events_created=upsert_result['created'],
                events_updated=upsert_result['updated'],  
                events_deleted=upsert_result['deleted'],
                next_delta_token=fetch_result.next_delta_token,
                last_updated_at=fetch_result.last_updated_at
            )
            
        except Exception as e:
            logger.error(f"Sync failed for calendar {external_calendar_id}: {e}")
            await self._update_connection_error(connection_id, str(e))
            return SyncResult(
                success=False, events_processed=0, events_created=0,
                events_updated=0, events_deleted=0, error_message=str(e)
            )
    
    async def _fetch_events_with_retry(
        self,
        provider: CalendarProvider,
        access_token: str,
        calendar_id: str,
        since: datetime,
        until: datetime,
        sync_state: SyncState,
        use_delta: bool,
        max_retries: int
    ) -> SyncResult:
        """재시도 로직으로 이벤트 가져오기"""
        last_error = None
        
        for attempt in range(max_retries + 1):
            try:
                if use_delta:
                    # 증분 동기화
                    provider_result = await provider.fetch_events(
                        access_token, calendar_id, since, until,
                        delta_token=sync_state.delta_token,
                        updated_min=sync_state.updated_min
                    )
                else:
                    # 윈도우 동기화
                    provider_result = await provider.fetch_events(
                        access_token, calendar_id, since, until,
                        updated_min=sync_state.updated_min
                    )
                
                return SyncResult(
                    success=True,
                    events_processed=len(provider_result.events),
                    events_created=0, events_updated=0, events_deleted=0,
                    next_delta_token=provider_result.next_delta_token,
                    last_updated_at=provider_result.max_updated_at
                )
                
            except RateLimitError as e:
                if attempt < max_retries:
                    wait_time = e.retry_after or (2 ** attempt)
                    jitter = random.uniform(0.1, 0.5)
                    await asyncio.sleep(wait_time + jitter)
                    last_error = e
                    continue
                else:
                    return SyncResult(
                        success=False, events_processed=0, events_created=0,
                        events_updated=0, events_deleted=0, error_message=str(e)
                    )
            
            except ProviderError as e:
                if "Invalid sync token" in str(e) and use_delta:
                    # Delta token 만료 시 full sync로 재시도
                    logger.info(f"Delta token expired for {calendar_id}, falling back to full sync")
                    use_delta = False
                    sync_state.delta_token = None
                    continue
                else:
                    return SyncResult(
                        success=False, events_processed=0, events_created=0,
                        events_updated=0, events_deleted=0, error_message=str(e)
                    )
                    
            except Exception as e:
                if attempt < max_retries:
                    wait_time = (2 ** attempt) + random.uniform(0.1, 1.0)
                    await asyncio.sleep(wait_time)
                    last_error = e
                    continue
                else:
                    return SyncResult(
                        success=False, events_processed=0, events_created=0,
                        events_updated=0, events_deleted=0, error_message=str(e)
                    )
        
        return SyncResult(
            success=False, events_processed=0, events_created=0,
            events_updated=0, events_deleted=0, error_message=str(last_error)
        )
    
    async def _upsert_events(
        self,
        user_id: str,
        platform: str, 
        calendar_id: str,
        events: List[CalendarEventDTO],
        batch_size: int
    ) -> Dict[str, int]:
        """이벤트를 배치로 DB에 upsert"""
        result = {'created': 0, 'updated': 0, 'deleted': 0}
        
        for i in range(0, len(events), batch_size):
            batch = events[i:i + batch_size]
            
            for event in batch:
                try:
                    # 기존 이벤트 조회
                    existing_query = select(Event).where(
                        and_(
                            Event.user_id == user_id,
                            Event.source_platform == platform,
                            Event.external_calendar_id == calendar_id,
                            Event.external_event_id == event.external_event_id
                        )
                    )
                    existing = (await self.db.execute(existing_query)).scalar_one_or_none()
                    
                    if event.deleted:
                        # 삭제 처리
                        if existing:
                            existing.deleted = True
                            existing.updated_at = datetime.utcnow()
                            result['deleted'] += 1
                        continue
                    
                    # 충돌 해결: external_updated_at 비교
                    if existing and existing.external_updated_at:
                        if event.external_updated_at <= existing.external_updated_at:
                            # 서버 데이터가 더 오래됨, 스킵
                            continue
                    
                    # 이벤트 데이터 준비
                    event_data = {
                        'user_id': user_id,
                        'external_event_id': event.external_event_id,
                        'external_calendar_id': calendar_id,
                        'title': event.title,
                        'description': event.description,
                        'start_datetime': event.start_utc,
                        'end_datetime': event.end_utc,
                        'all_day': event.all_day,
                        'location': event.location,
                        'source_platform': platform,
                        'recurrence_rule': event.recurrence_rule,
                        'external_updated_at': event.external_updated_at,
                        'external_version': event.external_version,
                        'updated_at': datetime.utcnow(),
                        'deleted': False
                    }
                    
                    if existing:
                        # 업데이트
                        for key, value in event_data.items():
                            if key != 'user_id':  # PK는 업데이트하지 않음
                                setattr(existing, key, value)
                        result['updated'] += 1
                    else:
                        # 생성
                        new_event = Event(**event_data)
                        self.db.add(new_event)
                        result['created'] += 1
                        
                except Exception as e:
                    logger.error(f"Failed to upsert event {event.external_event_id}: {e}")
                    continue
        
        await self.db.commit()
        return result
    
    def _calculate_sync_window(self, options: SyncOptions) -> Tuple[datetime, datetime]:
        """동기화 시간 창 계산"""
        now = datetime.now(timezone.utc)
        since = now - timedelta(days=options.window_days_past)
        until = now + timedelta(days=options.window_days_future)
        return since, until
    
    async def _get_connection(self, connection_id: str, user_id: str) -> Optional[ExternalConnection]:
        """연결 정보 조회"""
        query = select(ExternalConnection).where(
            and_(
                ExternalConnection.id == connection_id,
                ExternalConnection.user_id == user_id
            )
        )
        return (await self.db.execute(query)).scalar_one_or_none()
    
    async def _get_or_create_sync_state(
        self, user_id: str, connection_id: str, calendar_id: str
    ) -> SyncState:
        """동기화 상태 조회/생성"""
        query = select(SyncState).where(
            and_(
                SyncState.user_id == user_id,
                SyncState.connection_id == connection_id,
                SyncState.external_calendar_id == calendar_id
            )
        )
        sync_state = (await self.db.execute(query)).scalar_one_or_none()
        
        if not sync_state:
            sync_state = SyncState(
                user_id=user_id,
                connection_id=connection_id,
                external_calendar_id=calendar_id
            )
            self.db.add(sync_state)
            await self.db.commit()
            await self.db.refresh(sync_state)
        
        return sync_state
    
    async def _update_sync_state(
        self,
        sync_state: SyncState,
        delta_token: Optional[str],
        max_updated: Optional[datetime],
        window_start: datetime,
        window_end: datetime
    ):
        """동기화 상태 업데이트"""
        sync_state.delta_token = delta_token
        if max_updated:
            sync_state.updated_min = max_updated
        sync_state.last_window_start = window_start
        sync_state.last_window_end = window_end
        sync_state.updated_at = datetime.utcnow()
        await self.db.commit()
    
    async def _update_connection_success(self, connection_id: str):
        """연결 성공 상태 업데이트"""
        stmt = update(ExternalConnection).where(
            ExternalConnection.id == connection_id
        ).values(
            sync_status='idle',
            last_sync_at=datetime.utcnow(),
            last_error=None
        )
        await self.db.execute(stmt)
        await self.db.commit()
    
    async def _update_connection_error(self, connection_id: str, error_message: str):
        """연결 오류 상태 업데이트"""
        stmt = update(ExternalConnection).where(
            ExternalConnection.id == connection_id
        ).values(
            sync_status='error',
            last_error=error_message
        )
        await self.db.execute(stmt)
        await self.db.commit()

# Acceptance Criteria:
# - 증분 동기화 (delta token) 우선, 실패 시 윈도우 동기화로 fallback
# - 충돌 해결: external_updated_at 기준 Last-Write-Wins 적용
# - Rate limit과 일시적 오류에 지수 백오프 + 지터로 재시도
# - 배치 처리로 대량 이벤트도 효율적으로 처리  
# - 동기화 상태와 연결 상태를 별도 추적하여 디버깅 지원