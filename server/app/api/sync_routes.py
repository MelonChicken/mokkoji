"""Sync API endpoints for calendar synchronization

설계 의도:
- RESTful API로 클라이언트 동기화 요청 처리
- pull: 서버가 외부 캘린더에서 이벤트 가져오기
- push: 클라이언트 변경사항을 외부 캘린더에 반영
- state: 동기화 상태 조회로 UI 상태 표시 지원

"""
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from ..services.sync_service import CalendarSyncService, SyncOptions
from ..models.sync_models import SyncState, ExternalConnection
from ..core.database import get_db_session
from ..core.auth import get_current_user
from ..integrations.base import CalendarEventDTO

import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/sync", tags=["sync"])

# Request/Response Models
class SyncPullRequest(BaseModel):
    """서버 동기화 요청"""
    connection_ids: List[str] = Field(..., description="동기화할 연결 ID 목록")
    calendar_ids: Optional[List[str]] = Field(None, description="특정 캘린더만 동기화 (미지정 시 전체)")
    force_full: bool = Field(False, description="전체 동기화 강제 실행")
    window_days_past: int = Field(90, ge=1, le=365, description="과거 동기화 범위 (일)")
    window_days_future: int = Field(180, ge=1, le=730, description="미래 동기화 범위 (일)")

class EventPushData(BaseModel):
    """클라이언트 이벤트 업로드 데이터"""
    local_id: str = Field(..., description="로컬 이벤트 ID")
    external_event_id: Optional[str] = Field(None, description="외부 이벤트 ID (수정 시)")
    external_calendar_id: str = Field(..., description="대상 외부 캘린더 ID")
    title: str = Field(..., description="이벤트 제목")
    description: Optional[str] = None
    start_utc: datetime = Field(..., description="시작 시간 (UTC)")
    end_utc: Optional[datetime] = None
    all_day: bool = False
    location: Optional[str] = None
    recurrence_rule: Optional[str] = None
    attendees: List[Dict[str, Any]] = Field(default_factory=list)
    action: str = Field(..., regex="^(create|update|delete)$", description="작업 유형")

class SyncPushRequest(BaseModel):
    """클라이언트 변경사항 업로드"""
    connection_id: str = Field(..., description="대상 연결 ID")
    events: List[EventPushData] = Field(..., description="변경할 이벤트 목록")

class SyncStateResponse(BaseModel):
    """동기화 상태 응답"""
    connection_id: str
    platform_type: str
    sync_enabled: bool
    sync_status: str  # idle, syncing, error
    last_sync_at: Optional[datetime]
    last_error: Optional[str]
    calendars: List[Dict[str, Any]]

class SyncResultResponse(BaseModel):
    """동기화 결과 응답"""
    success: bool
    message: str
    results: List[Dict[str, Any]]

# Dependencies
async def get_sync_service(db: AsyncSession = Depends(get_db_session)) -> CalendarSyncService:
    """동기화 서비스 의존성 주입"""
    return CalendarSyncService(db)

# Endpoints
@router.post("/pull", response_model=SyncResultResponse)
async def sync_pull(
    request: SyncPullRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
    sync_service: CalendarSyncService = Depends(get_sync_service)
):
    """
    외부 캘린더에서 서버로 이벤트 동기화
    
    백그라운드에서 실행하여 응답 시간 단축
    """
    user_id = current_user["sub"]
    
    try:
        # 연결 유효성 검증
        valid_connections = await _validate_connections(
            sync_service.db, user_id, request.connection_ids
        )
        
        if not valid_connections:
            raise HTTPException(status_code=400, detail="No valid connections found")
        
        # 동기화 옵션 구성
        sync_options = SyncOptions(
            force_full=request.force_full,
            window_days_past=request.window_days_past,
            window_days_future=request.window_days_future
        )
        
        # 백그라운드에서 동기화 실행
        sync_results = []
        for connection in valid_connections:
            # 해당 연결의 모든 캘린더 또는 지정된 캘린더만 동기화
            calendars_to_sync = request.calendar_ids or await _get_user_calendars(
                sync_service, connection.id, connection.access_token_encrypted
            )
            
            for calendar_id in calendars_to_sync:
                background_tasks.add_task(
                    _sync_calendar_background,
                    sync_service, user_id, connection.id, calendar_id, sync_options
                )
                
                sync_results.append({
                    'connection_id': connection.id,
                    'calendar_id': calendar_id,
                    'status': 'queued'
                })
        
        return SyncResultResponse(
            success=True,
            message=f"Queued {len(sync_results)} calendar sync tasks",
            results=sync_results
        )
        
    except Exception as e:
        logger.error(f"Sync pull failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/push", response_model=SyncResultResponse)
async def sync_push(
    request: SyncPushRequest,
    current_user: dict = Depends(get_current_user),
    sync_service: CalendarSyncService = Depends(get_sync_service)
):
    """
    클라이언트 변경사항을 외부 캘린더에 반영
    """
    user_id = current_user["sub"]
    
    try:
        # 연결 유효성 검증
        connection = await _get_connection(
            sync_service.db, request.connection_id, user_id
        )
        
        if not connection or not connection.sync_enabled:
            raise HTTPException(status_code=400, detail="Invalid or disabled connection")
        
        # 제공자 가져오기
        provider = sync_service.providers.get(connection.platform_type)
        if not provider or not provider.capabilities.write:
            raise HTTPException(
                status_code=400, 
                detail=f"Provider {connection.platform_type} does not support writing"
            )
        
        # 액세스 토큰 복호화
        from ..core.security import decrypt_token
        access_token = await decrypt_token(
            connection.access_token_encrypted, 
            request.connection_id
        )
        
        # 각 이벤트 처리
        results = []
        for event_data in request.events:
            try:
                result = await _process_event_push(
                    provider, access_token, event_data, connection.platform_type
                )
                results.append(result)
                
            except Exception as e:
                logger.error(f"Failed to push event {event_data.local_id}: {e}")
                results.append({
                    'local_id': event_data.local_id,
                    'success': False,
                    'error': str(e)
                })
        
        # 성공한 작업 수 계산
        success_count = sum(1 for r in results if r.get('success', False))
        
        return SyncResultResponse(
            success=success_count > 0,
            message=f"Processed {len(results)} events, {success_count} successful",
            results=results
        )
        
    except Exception as e:
        logger.error(f"Sync push failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/state", response_model=List[SyncStateResponse])
async def get_sync_state(
    current_user: dict = Depends(get_current_user),
    sync_service: CalendarSyncService = Depends(get_sync_service)
):
    """
    사용자의 모든 연결에 대한 동기화 상태 조회
    """
    user_id = current_user["sub"]
    
    try:
        # 사용자의 모든 연결 조회
        connections_query = select(ExternalConnection).where(
            ExternalConnection.user_id == user_id
        )
        connections = (await sync_service.db.execute(connections_query)).scalars().all()
        
        states = []
        for connection in connections:
            # 각 연결의 동기화 상태 조회
            sync_states_query = select(SyncState).where(
                SyncState.connection_id == connection.id
            )
            sync_states = (await sync_service.db.execute(sync_states_query)).scalars().all()
            
            # 캘린더 정보 구성
            calendars = []
            for state in sync_states:
                calendars.append({
                    'external_calendar_id': state.external_calendar_id,
                    'last_sync_window_start': state.last_window_start.isoformat() if state.last_window_start else None,
                    'last_sync_window_end': state.last_window_end.isoformat() if state.last_window_end else None,
                    'has_delta_token': bool(state.delta_token),
                    'updated_min': state.updated_min.isoformat() if state.updated_min else None
                })
            
            states.append(SyncStateResponse(
                connection_id=connection.id,
                platform_type=connection.platform_type,
                sync_enabled=connection.sync_enabled,
                sync_status=connection.sync_status,
                last_sync_at=connection.last_sync_at,
                last_error=connection.last_error,
                calendars=calendars
            ))
        
        return states
        
    except Exception as e:
        logger.error(f"Get sync state failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Helper Functions
async def _validate_connections(
    db: AsyncSession, 
    user_id: str, 
    connection_ids: List[str]
) -> List[ExternalConnection]:
    """연결 유효성 검증"""
    query = select(ExternalConnection).where(
        and_(
            ExternalConnection.user_id == user_id,
            ExternalConnection.id.in_(connection_ids),
            ExternalConnection.sync_enabled == True
        )
    )
    return (await db.execute(query)).scalars().all()

async def _get_connection(
    db: AsyncSession, 
    connection_id: str, 
    user_id: str
) -> Optional[ExternalConnection]:
    """단일 연결 조회"""
    query = select(ExternalConnection).where(
        and_(
            ExternalConnection.id == connection_id,
            ExternalConnection.user_id == user_id
        )
    )
    return (await db.execute(query)).scalar_one_or_none()

async def _get_user_calendars(
    sync_service: CalendarSyncService,
    connection_id: str,
    encrypted_token: str
) -> List[str]:
    """사용자의 캘린더 ID 목록 조회"""
    # 실제 구현에서는 캐시된 캘린더 목록 또는 제공자 API 호출
    # 여기서는 기본 캘린더 반환
    return ["primary"]

async def _sync_calendar_background(
    sync_service: CalendarSyncService,
    user_id: str,
    connection_id: str, 
    calendar_id: str,
    options: SyncOptions
):
    """백그라운드 캘린더 동기화 실행"""
    try:
        result = await sync_service.sync_calendar(
            user_id, connection_id, calendar_id, options
        )
        logger.info(f"Background sync completed: {result}")
    except Exception as e:
        logger.error(f"Background sync failed: {e}")

async def _process_event_push(
    provider,
    access_token: str,
    event_data: EventPushData,
    platform: str
) -> Dict[str, Any]:
    """개별 이벤트 push 처리"""
    try:
        # DTO 변환
        event_dto = CalendarEventDTO(
            external_event_id=event_data.external_event_id,
            calendar_id=event_data.external_calendar_id,
            title=event_data.title,
            description=event_data.description,
            start_utc=event_data.start_utc,
            end_utc=event_data.end_utc,
            all_day=event_data.all_day,
            location=event_data.location,
            recurrence_rule=event_data.recurrence_rule,
            attendees=event_data.attendees
        )
        
        if event_data.action == "delete":
            # 삭제 처리
            if not event_data.external_event_id:
                raise ValueError("external_event_id required for delete")
            
            await provider.delete_event(
                access_token,
                event_data.external_calendar_id,
                event_data.external_event_id
            )
            
            return {
                'local_id': event_data.local_id,
                'action': 'delete',
                'success': True
            }
        
        else:
            # 생성/수정 처리
            result_event = await provider.upsert_event(
                access_token,
                event_data.external_calendar_id,
                event_dto
            )
            
            return {
                'local_id': event_data.local_id,
                'action': event_data.action,
                'success': True,
                'external_event_id': result_event.external_event_id,
                'external_version': result_event.external_version,
                'external_updated_at': result_event.external_updated_at.isoformat()
            }
            
    except Exception as e:
        raise e

# Acceptance Criteria:
# - /api/sync/pull로 외부 캘린더에서 서버로 이벤트 동기화
# - /api/sync/push로 클라이언트 변경사항을 외부 캘린더에 반영
# - /api/sync/state로 동기화 상태 조회 및 UI 표시 지원
# - 백그라운드 작업으로 동기화 성능 최적화
# - 적절한 오류 처리와 로깅으로 디버깅 지원