"""AI-powered voice event modification endpoints

음성으로 일정 수정 (v1) - LangChain 없이 OpenAI 함수 호출 직접 사용

설계 원칙:
- OpenAI function calling으로 사용자 의도 파악
- REST API로 실제 데이터베이스 작업 수행
- STT는 파일 업로드 방식으로 처리
- PostgreSQL events 스키마와 호환

"""
import os
import json
import logging
from datetime import datetime, timezone, timedelta
from typing import List, Optional, Dict, Any, Literal
from pydantic import BaseModel, Field, validator
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func
import openai
from openai import AsyncOpenAI

from ..core.database import get_db_session
from ..core.auth import get_current_user
from ..models.event_models import Event, Calendar
from ..models.sync_models import SyncState

logger = logging.getLogger(__name__)

# OpenAI 클라이언트 초기화
openai_client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

router = APIRouter(prefix="/ai", tags=["ai"])

# Pydantic Models
class EventFindRequest(BaseModel):
    """이벤트 검색 요청"""
    query: str = Field(..., description="검색 쿼리 (제목, 설명 등)")
    start_date: Optional[str] = Field(None, description="검색 시작일 (YYYY-MM-DD)")
    end_date: Optional[str] = Field(None, description="검색 종료일 (YYYY-MM-DD)")
    limit: int = Field(10, ge=1, le=50, description="최대 결과 수")

class EventRescheduleRequest(BaseModel):
    """일정 재조정 요청"""
    event_id: str = Field(..., description="이벤트 ID")
    new_start_utc: str = Field(..., description="새 시작 시간 (ISO format)")
    new_end_utc: Optional[str] = Field(None, description="새 종료 시간 (ISO format)")

class EventUpdateFieldsRequest(BaseModel):
    """이벤트 필드 업데이트 요청"""
    event_id: str = Field(..., description="이벤트 ID")
    title: Optional[str] = Field(None, description="새 제목")
    description: Optional[str] = Field(None, description="새 설명")
    location: Optional[str] = Field(None, description="새 위치")

class EventCancelRequest(BaseModel):
    """이벤트 취소 요청"""
    event_id: str = Field(..., description="이벤트 ID")
    cancel_scope: Literal["single", "future", "all"] = Field("single", description="취소 범위")

class ConflictCheckRequest(BaseModel):
    """일정 충돌 확인 요청"""
    start_utc: str = Field(..., description="시작 시간 (ISO format)")
    end_utc: str = Field(..., description="종료 시간 (ISO format)")
    exclude_event_id: Optional[str] = Field(None, description="제외할 이벤트 ID")

class VoiceEventRequest(BaseModel):
    """음성 이벤트 처리 요청"""
    user_message: str = Field(..., description="사용자 음성 텍스트")

# OpenAI 함수 정의
OPENAI_FUNCTIONS = [
    {
        "name": "find_event",
        "description": "사용자의 이벤트를 검색합니다",
        "parameters": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "검색할 이벤트의 제목이나 키워드"
                },
                "start_date": {
                    "type": "string",
                    "description": "검색 시작 날짜 (YYYY-MM-DD 형식)"
                },
                "end_date": {
                    "type": "string",
                    "description": "검색 종료 날짜 (YYYY-MM-DD 형식)"
                }
            },
            "required": ["query"]
        }
    },
    {
        "name": "reschedule_event",
        "description": "이벤트의 시간을 변경합니다",
        "parameters": {
            "type": "object",
            "properties": {
                "event_id": {
                    "type": "string",
                    "description": "변경할 이벤트의 ID"
                },
                "new_start_utc": {
                    "type": "string",
                    "description": "새로운 시작 시간 (ISO 8601 UTC 형식)"
                },
                "new_end_utc": {
                    "type": "string",
                    "description": "새로운 종료 시간 (ISO 8601 UTC 형식)"
                }
            },
            "required": ["event_id", "new_start_utc"]
        }
    },
    {
        "name": "update_event_fields",
        "description": "이벤트의 제목, 설명, 위치 등을 수정합니다",
        "parameters": {
            "type": "object",
            "properties": {
                "event_id": {
                    "type": "string",
                    "description": "수정할 이벤트의 ID"
                },
                "title": {
                    "type": "string",
                    "description": "새로운 제목"
                },
                "description": {
                    "type": "string",
                    "description": "새로운 설명"
                },
                "location": {
                    "type": "string",
                    "description": "새로운 위치"
                }
            },
            "required": ["event_id"]
        }
    },
    {
        "name": "cancel_event",
        "description": "이벤트를 취소합니다",
        "parameters": {
            "type": "object",
            "properties": {
                "event_id": {
                    "type": "string",
                    "description": "취소할 이벤트의 ID"
                },
                "cancel_scope": {
                    "type": "string",
                    "enum": ["single", "future", "all"],
                    "description": "취소 범위: single(단일), future(이후 모든 반복), all(모든 반복)"
                }
            },
            "required": ["event_id"]
        }
    },
    {
        "name": "check_conflicts",
        "description": "특정 시간대의 일정 충돌을 확인합니다",
        "parameters": {
            "type": "object",
            "properties": {
                "start_utc": {
                    "type": "string",
                    "description": "확인할 시작 시간 (ISO 8601 UTC 형식)"
                },
                "end_utc": {
                    "type": "string",
                    "description": "확인할 종료 시간 (ISO 8601 UTC 형식)"
                },
                "exclude_event_id": {
                    "type": "string",
                    "description": "충돌 검사에서 제외할 이벤트 ID"
                }
            },
            "required": ["start_utc", "end_utc"]
        }
    }
]

# Helper Functions
async def get_user_events(db: AsyncSession, user_id: str) -> List[Event]:
    """사용자 이벤트 조회"""
    query = select(Event).join(Calendar).where(
        and_(
            Calendar.user_id == user_id,
            Event.deleted == False
        )
    )
    result = await db.execute(query)
    return result.scalars().all()

async def find_event_by_id(db: AsyncSession, event_id: str, user_id: str) -> Optional[Event]:
    """ID로 이벤트 찾기"""
    query = select(Event).join(Calendar).where(
        and_(
            Event.id == event_id,
            Calendar.user_id == user_id,
            Event.deleted == False
        )
    )
    result = await db.execute(query)
    return result.scalar_one_or_none()

# API Endpoints
@router.post("/find_event")
async def find_event(
    request: EventFindRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: dict = Depends(get_current_user)
):
    """이벤트 검색"""
    user_id = current_user["sub"]

    try:
        # 기본 쿼리 구성
        query = select(Event).join(Calendar).where(
            and_(
                Calendar.user_id == user_id,
                Event.deleted == False
            )
        )

        # 텍스트 검색
        if request.query:
            search_filter = or_(
                Event.title.ilike(f"%{request.query}%"),
                Event.description.ilike(f"%{request.query}%"),
                Event.location.ilike(f"%{request.query}%")
            )
            query = query.where(search_filter)

        # 날짜 범위 필터
        if request.start_date:
            start_timestamp = int(datetime.fromisoformat(f"{request.start_date}T00:00:00+00:00").timestamp())
            query = query.where(Event.start_utc >= start_timestamp)

        if request.end_date:
            end_timestamp = int(datetime.fromisoformat(f"{request.end_date}T23:59:59+00:00").timestamp())
            query = query.where(Event.end_utc <= end_timestamp)

        query = query.order_by(Event.start_utc).limit(request.limit)

        result = await db.execute(query)
        events = result.scalars().all()

        # 결과 포맷팅
        formatted_events = []
        for event in events:
            formatted_events.append({
                "id": event.id,
                "title": event.title,
                "description": event.description,
                "start_utc": datetime.fromtimestamp(event.start_utc, tz=timezone.utc).isoformat(),
                "end_utc": datetime.fromtimestamp(event.end_utc, tz=timezone.utc).isoformat() if event.end_utc else None,
                "location": event.location,
                "all_day": event.all_day
            })

        return {"success": True, "events": formatted_events, "count": len(formatted_events)}

    except Exception as e:
        logger.error(f"Find event failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/reschedule")
async def reschedule_event(
    request: EventRescheduleRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: dict = Depends(get_current_user)
):
    """이벤트 시간 변경"""
    user_id = current_user["sub"]

    try:
        # 이벤트 존재 확인
        event = await find_event_by_id(db, request.event_id, user_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")

        # 시간 파싱
        new_start = datetime.fromisoformat(request.new_start_utc.replace('Z', '+00:00'))
        new_end = None
        if request.new_end_utc:
            new_end = datetime.fromisoformat(request.new_end_utc.replace('Z', '+00:00'))
        else:
            # 기존 duration 유지
            if event.end_utc:
                duration = event.end_utc - event.start_utc
                new_end = new_start + timedelta(seconds=duration)

        # 이벤트 업데이트
        event.start_utc = int(new_start.timestamp())
        if new_end:
            event.end_utc = int(new_end.timestamp())
        event.last_modified_local = int(datetime.now(timezone.utc).timestamp())
        event.sync_status = 'pending'

        await db.commit()

        return {
            "success": True,
            "message": "Event rescheduled successfully",
            "event": {
                "id": event.id,
                "title": event.title,
                "start_utc": new_start.isoformat(),
                "end_utc": new_end.isoformat() if new_end else None
            }
        }

    except Exception as e:
        await db.rollback()
        logger.error(f"Reschedule event failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/update_fields")
async def update_event_fields(
    request: EventUpdateFieldsRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: dict = Depends(get_current_user)
):
    """이벤트 필드 업데이트"""
    user_id = current_user["sub"]

    try:
        # 이벤트 존재 확인
        event = await find_event_by_id(db, request.event_id, user_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")

        # 필드 업데이트
        if request.title is not None:
            event.title = request.title
        if request.description is not None:
            event.description = request.description
        if request.location is not None:
            event.location = request.location

        event.last_modified_local = int(datetime.now(timezone.utc).timestamp())
        event.sync_status = 'pending'

        await db.commit()

        return {
            "success": True,
            "message": "Event updated successfully",
            "event": {
                "id": event.id,
                "title": event.title,
                "description": event.description,
                "location": event.location
            }
        }

    except Exception as e:
        await db.rollback()
        logger.error(f"Update event fields failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/cancel")
async def cancel_event(
    request: EventCancelRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: dict = Depends(get_current_user)
):
    """이벤트 취소"""
    user_id = current_user["sub"]

    try:
        # 이벤트 존재 확인
        event = await find_event_by_id(db, request.event_id, user_id)
        if not event:
            raise HTTPException(status_code=404, detail="Event not found")

        # 취소 처리 (soft delete)
        event.deleted = True
        event.last_modified_local = int(datetime.now(timezone.utc).timestamp())
        event.sync_status = 'pending'

        await db.commit()

        return {
            "success": True,
            "message": f"Event cancelled successfully (scope: {request.cancel_scope})",
            "event_id": event.id
        }

    except Exception as e:
        await db.rollback()
        logger.error(f"Cancel event failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/check_conflicts")
async def check_conflicts(
    start_utc: str,
    end_utc: str,
    exclude_event_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db_session),
    current_user: dict = Depends(get_current_user)
):
    """일정 충돌 확인"""
    user_id = current_user["sub"]

    try:
        # 시간 파싱
        start_time = datetime.fromisoformat(start_utc.replace('Z', '+00:00'))
        end_time = datetime.fromisoformat(end_utc.replace('Z', '+00:00'))

        start_timestamp = int(start_time.timestamp())
        end_timestamp = int(end_time.timestamp())

        # 충돌 확인 쿼리
        query = select(Event).join(Calendar).where(
            and_(
                Calendar.user_id == user_id,
                Event.deleted == False,
                or_(
                    and_(Event.start_utc <= start_timestamp, Event.end_utc > start_timestamp),
                    and_(Event.start_utc < end_timestamp, Event.end_utc >= end_timestamp),
                    and_(Event.start_utc >= start_timestamp, Event.end_utc <= end_timestamp)
                )
            )
        )

        if exclude_event_id:
            query = query.where(Event.id != exclude_event_id)

        result = await db.execute(query)
        conflicts = result.scalars().all()

        # 결과 포맷팅
        conflicting_events = []
        for event in conflicts:
            conflicting_events.append({
                "id": event.id,
                "title": event.title,
                "start_utc": datetime.fromtimestamp(event.start_utc, tz=timezone.utc).isoformat(),
                "end_utc": datetime.fromtimestamp(event.end_utc, tz=timezone.utc).isoformat() if event.end_utc else None
            })

        return {
            "has_conflicts": len(conflicts) > 0,
            "conflict_count": len(conflicts),
            "conflicting_events": conflicting_events
        }

    except Exception as e:
        logger.error(f"Check conflicts failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/transcribe")
async def transcribe_audio(
    audio_file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """음성 파일을 텍스트로 변환"""
    try:
        # 파일 유효성 검사
        if not audio_file.content_type or not audio_file.content_type.startswith('audio/'):
            raise HTTPException(status_code=400, detail="Audio file required")

        # OpenAI Whisper로 STT
        audio_content = await audio_file.read()

        response = await openai_client.audio.transcriptions.create(
            model="whisper-1",
            file=(audio_file.filename, audio_content, audio_file.content_type),
            language="ko"
        )

        return {
            "success": True,
            "transcription": response.text,
            "filename": audio_file.filename
        }

    except Exception as e:
        logger.error(f"Audio transcription failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/process_voice")
async def process_voice_command(
    request: VoiceEventRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: dict = Depends(get_current_user)
):
    """음성 명령 처리 (OpenAI 함수 호출 사용)"""
    user_id = current_user["sub"]

    try:
        # OpenAI 함수 호출로 의도 파악
        response = await openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "system",
                    "content": """당신은 일정 관리 AI 어시스턴트입니다.
사용자의 음성 명령을 분석하여 적절한 함수를 호출하세요.
- 일정 찾기: find_event
- 일정 시간 변경: reschedule_event
- 일정 내용 수정: update_event_fields
- 일정 취소: cancel_event
- 충돌 확인: check_conflicts

현재 시간은 한국 시간 기준입니다. 날짜/시간을 UTC로 변환하여 전달하세요."""
                },
                {"role": "user", "content": request.user_message}
            ],
            functions=OPENAI_FUNCTIONS,
            function_call="auto"
        )

        message = response.choices[0].message

        if message.function_call:
            function_name = message.function_call.name
            function_args = json.loads(message.function_call.arguments)

            # 해당 함수 실행
            if function_name == "find_event":
                find_request = EventFindRequest(**function_args)
                result = await find_event(find_request, db, current_user)

            elif function_name == "reschedule_event":
                reschedule_request = EventRescheduleRequest(**function_args)
                result = await reschedule_event(reschedule_request, db, current_user)

            elif function_name == "update_event_fields":
                update_request = EventUpdateFieldsRequest(**function_args)
                result = await update_event_fields(update_request, db, current_user)

            elif function_name == "cancel_event":
                cancel_request = EventCancelRequest(**function_args)
                result = await cancel_event(cancel_request, db, current_user)

            elif function_name == "check_conflicts":
                conflict_result = await check_conflicts(
                    function_args["start_utc"],
                    function_args["end_utc"],
                    function_args.get("exclude_event_id"),
                    db,
                    current_user
                )
                result = conflict_result

            else:
                raise HTTPException(status_code=400, detail=f"Unknown function: {function_name}")

            return {
                "success": True,
                "function_called": function_name,
                "function_args": function_args,
                "result": result,
                "ai_response": message.content
            }
        else:
            # 함수 호출이 없는 경우
            return {
                "success": True,
                "function_called": None,
                "ai_response": message.content,
                "message": "No specific action identified from voice command"
            }

    except Exception as e:
        logger.error(f"Voice command processing failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Health check
@router.get("/health")
async def ai_health_check():
    """AI 서비스 상태 확인"""
    try:
        # OpenAI API 키 확인
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            return {"status": "error", "message": "OpenAI API key not configured"}

        return {
            "status": "healthy",
            "features": {
                "voice_transcription": True,
                "function_calling": True,
                "event_operations": True
            }
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}