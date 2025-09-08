"""Test suite for calendar sync service

테스트 범위:
- Provider mock을 통한 단위 테스트
- 동기화 로직 (upsert/delete/conflict) 테스트  
- 재시도 정책 및 백오프 테스트
- 배치 처리 및 성능 테스트

"""
import pytest
import asyncio
from datetime import datetime, timezone, timedelta
from unittest.mock import AsyncMock, MagicMock, patch
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.services.sync_service import CalendarSyncService, SyncOptions, SyncResult
from app.integrations.base import CalendarEventDTO, ProviderError, RateLimitError
from app.models.sync_models import SyncState, ExternalConnection, Event
from app.core.database import Base

class TestSyncService:
    """CalendarSyncService 테스트 클래스"""

    @pytest.fixture
    async def db_session(self):
        """테스트용 인메모리 DB 세션"""
        engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
        
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        async_session = sessionmaker(
            engine, class_=AsyncSession, expire_on_commit=False
        )
        
        async with async_session() as session:
            yield session

    @pytest.fixture
    def mock_provider(self):
        """Mock 캘린더 제공자"""
        provider = MagicMock()
        provider.name = "google"
        provider.capabilities.read = True
        provider.capabilities.write = True  
        provider.capabilities.delta = True
        return provider

    @pytest.fixture
    async def sync_service(self, db_session, mock_provider):
        """테스트용 SyncService 인스턴스"""
        service = CalendarSyncService(db_session)
        service.providers = {"google": mock_provider}
        return service

    @pytest.fixture
    def sample_events(self):
        """테스트용 샘플 이벤트 데이터"""
        now = datetime.now(timezone.utc)
        return [
            CalendarEventDTO(
                external_event_id="evt_1",
                calendar_id="cal_1", 
                title="Meeting 1",
                description="Team meeting",
                start_utc=now,
                end_utc=now + timedelta(hours=1),
                all_day=False,
                location="Conference Room",
                external_updated_at=now,
                external_version="v1"
            ),
            CalendarEventDTO(
                external_event_id="evt_2",
                calendar_id="cal_1",
                title="All Day Event", 
                description=None,
                start_utc=now.replace(hour=0, minute=0, second=0),
                end_utc=None,
                all_day=True,
                location=None,
                external_updated_at=now,
                external_version="v1"
            )
        ]

    @pytest.mark.asyncio
    async def test_sync_calendar_success(self, sync_service, mock_provider, sample_events, db_session):
        """정상적인 캘린더 동기화 테스트"""
        # Arrange
        user_id = "user_123"
        connection_id = "conn_123"
        calendar_id = "cal_primary"
        
        # 연결 정보 세팅
        connection = ExternalConnection(
            id=connection_id,
            user_id=user_id,
            platform_type="google",
            access_token_encrypted="encrypted_token",
            sync_enabled=True
        )
        db_session.add(connection)
        await db_session.commit()

        # Provider mock 설정
        mock_provider.fetch_events.return_value = MagicMock(
            events=sample_events,
            next_delta_token="delta_123",
            max_updated_at=datetime.now(timezone.utc)
        )

        # Act
        result = await sync_service.sync_calendar(user_id, connection_id, calendar_id)

        # Assert
        assert result.success is True
        assert result.events_processed == 2
        assert result.events_created == 2
        assert result.next_delta_token == "delta_123"

        # DB에 이벤트가 저장되었는지 확인
        events_in_db = await sync_service._get_events_by_external_ids(
            user_id, "google", calendar_id, ["evt_1", "evt_2"]
        )
        assert len(events_in_db) == 2

    @pytest.mark.asyncio
    async def test_sync_calendar_with_conflicts(self, sync_service, mock_provider, db_session):
        """충돌이 있는 동기화 테스트"""
        # Arrange
        user_id = "user_123"
        connection_id = "conn_123"
        calendar_id = "cal_primary"
        
        # 기존 이벤트 (로컬에서 수정됨)
        now = datetime.now(timezone.utc)
        existing_event = Event(
            user_id=user_id,
            external_event_id="evt_conflict",
            external_calendar_id=calendar_id,
            title="Original Title",
            description="Original description",
            start_datetime=now,
            end_datetime=now + timedelta(hours=1),
            source_platform="google",
            external_updated_at=now - timedelta(minutes=30),  # 30분 전
            external_version="v1",
            updated_at=now - timedelta(minutes=15)  # 15분 전에 로컬 수정
        )
        db_session.add(existing_event)
        await db_session.commit()

        # 서버에서 온 업데이트된 이벤트 (더 최신)
        updated_event = CalendarEventDTO(
            external_event_id="evt_conflict",
            calendar_id=calendar_id,
            title="Updated Title",  # 변경됨
            description="Updated description",  # 변경됨
            start_utc=now,
            end_utc=now + timedelta(hours=1),
            all_day=False,
            external_updated_at=now,  # 더 최신
            external_version="v2"
        )

        mock_provider.fetch_events.return_value = MagicMock(
            events=[updated_event],
            next_delta_token="delta_456",
            max_updated_at=now
        )

        # Act
        result = await sync_service.sync_calendar(user_id, connection_id, calendar_id)

        # Assert
        assert result.success is True
        assert result.events_updated == 1

        # 서버 버전이 적용되었는지 확인 (Last-Write-Wins)
        updated_in_db = await sync_service._get_event_by_external_id(
            user_id, "google", calendar_id, "evt_conflict"
        )
        assert updated_in_db.title == "Updated Title"
        assert updated_in_db.external_version == "v2"

    @pytest.mark.asyncio
    async def test_sync_with_rate_limit_retry(self, sync_service, mock_provider):
        """Rate limit 재시도 테스트"""
        # Arrange
        user_id = "user_123"
        connection_id = "conn_123"
        calendar_id = "cal_primary"

        # 첫 번째 호출에서 RateLimitError, 두 번째 호출에서 성공
        mock_provider.fetch_events.side_effect = [
            RateLimitError("google", 60),  # 60초 대기
            MagicMock(
                events=[],
                next_delta_token=None,
                max_updated_at=datetime.now(timezone.utc)
            )
        ]

        # Act & Assert
        with patch('asyncio.sleep') as mock_sleep:  # sleep 모킹
            result = await sync_service.sync_calendar(user_id, connection_id, calendar_id)
            
            # 재시도가 발생했는지 확인
            assert mock_provider.fetch_events.call_count == 2
            mock_sleep.assert_called_once()  # sleep이 호출됨
            assert result.success is True

    @pytest.mark.asyncio  
    async def test_sync_with_provider_error(self, sync_service, mock_provider):
        """제공자 오류 시 처리 테스트"""
        # Arrange
        user_id = "user_123"
        connection_id = "conn_123" 
        calendar_id = "cal_primary"

        mock_provider.fetch_events.side_effect = ProviderError("API quota exceeded", "google")

        # Act
        result = await sync_service.sync_calendar(user_id, connection_id, calendar_id)

        # Assert
        assert result.success is False
        assert "API quota exceeded" in result.error_message

    @pytest.mark.asyncio
    async def test_batch_upsert_performance(self, sync_service, db_session):
        """배치 upsert 성능 테스트"""
        # Arrange - 1000개 이벤트 생성
        user_id = "user_123"
        platform = "google"
        calendar_id = "cal_primary"
        
        events = []
        now = datetime.now(timezone.utc)
        for i in range(1000):
            events.append(CalendarEventDTO(
                external_event_id=f"evt_{i}",
                calendar_id=calendar_id,
                title=f"Event {i}",
                description=f"Description {i}",
                start_utc=now + timedelta(hours=i),
                end_utc=now + timedelta(hours=i+1),
                all_day=False,
                external_updated_at=now,
                external_version="v1"
            ))

        # Act - 시간 측정
        start_time = datetime.now()
        result = await sync_service._upsert_events(
            user_id, platform, calendar_id, events, batch_size=100
        )
        end_time = datetime.now()

        # Assert
        assert result['created'] == 1000
        assert result['updated'] == 0
        
        # 성능 확인 (10초 이내)
        processing_time = (end_time - start_time).total_seconds()
        assert processing_time < 10.0, f"Processing took {processing_time}s, expected < 10s"

    @pytest.mark.asyncio
    async def test_delta_token_fallback(self, sync_service, mock_provider):
        """Delta token 만료 시 full sync fallback 테스트"""
        # Arrange
        user_id = "user_123"
        connection_id = "conn_123"
        calendar_id = "cal_primary"

        # 첫 번째: Invalid delta token 오류
        # 두 번째: 정상 full sync
        mock_provider.fetch_events.side_effect = [
            ProviderError("Invalid sync token", "google"),
            MagicMock(
                events=[],
                next_delta_token="new_delta_123",
                max_updated_at=datetime.now(timezone.utc)
            )
        ]

        # Act
        result = await sync_service.sync_calendar(user_id, connection_id, calendar_id)

        # Assert
        assert result.success is True
        assert mock_provider.fetch_events.call_count == 2
        
        # 첫 번째 호출은 delta token 사용
        first_call = mock_provider.fetch_events.call_args_list[0]
        assert 'delta_token' in first_call[1]
        
        # 두 번째 호출은 delta token 없음 (full sync)
        second_call = mock_provider.fetch_events.call_args_list[1] 
        assert first_call[1].get('delta_token') != second_call[1].get('delta_token')

    @pytest.mark.asyncio
    async def test_deleted_event_processing(self, sync_service, sample_events, db_session):
        """삭제된 이벤트 처리 테스트"""
        # Arrange
        user_id = "user_123"
        platform = "google"
        calendar_id = "cal_primary"

        # 기존 이벤트 추가
        existing_event = Event(
            user_id=user_id,
            external_event_id="evt_to_delete",
            external_calendar_id=calendar_id,
            title="To Be Deleted",
            start_datetime=datetime.now(timezone.utc),
            source_platform=platform,
            deleted=False
        )
        db_session.add(existing_event)
        await db_session.commit()

        # 삭제된 이벤트 DTO
        deleted_event = CalendarEventDTO(
            external_event_id="evt_to_delete",
            calendar_id=calendar_id,
            title="To Be Deleted",
            start_utc=datetime.now(timezone.utc),
            deleted=True,  # 삭제 표시
            external_updated_at=datetime.now(timezone.utc)
        )

        # Act
        result = await sync_service._upsert_events(
            user_id, platform, calendar_id, [deleted_event], batch_size=10
        )

        # Assert
        assert result['deleted'] == 1
        
        # DB에서 삭제 마킹 확인
        updated_event = await sync_service._get_event_by_external_id(
            user_id, platform, calendar_id, "evt_to_delete"
        )
        assert updated_event.deleted is True

class TestProviderIntegration:
    """Provider 통합 테스트"""

    @pytest.mark.asyncio
    async def test_google_provider_integration(self):
        """Google Provider 실제 API 호출 테스트 (선택적)"""
        # 실제 API 호출은 환경변수로 제어
        import os
        if not os.getenv('RUN_INTEGRATION_TESTS'):
            pytest.skip("Integration tests disabled")
        
        from app.integrations.google_provider import GoogleCalendarProvider
        
        # Arrange
        client_id = os.getenv('GOOGLE_CLIENT_ID')
        client_secret = os.getenv('GOOGLE_CLIENT_SECRET') 
        access_token = os.getenv('GOOGLE_ACCESS_TOKEN')
        
        if not all([client_id, client_secret, access_token]):
            pytest.skip("Google credentials not available")

        provider = GoogleCalendarProvider(client_id, client_secret)

        # Act - 캘린더 목록 조회
        calendars = await provider.list_calendars(access_token)

        # Assert
        assert len(calendars) > 0
        assert any(cal.primary for cal in calendars)  # primary 캘린더 존재

    @pytest.mark.asyncio
    async def test_naver_provider_ics_parsing(self):
        """Naver Provider ICS 파싱 테스트"""
        from app.integrations.naver_provider import NaverCalendarProvider

        provider = NaverCalendarProvider("client_id", "client_secret")
        
        # 샘플 ICS 데이터
        sample_ics = """BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//Test Calendar//EN
BEGIN:VEVENT
UID:test-event-123
DTSTART:20240101T090000Z
DTEND:20240101T100000Z
SUMMARY:테스트 이벤트
DESCRIPTION:테스트 설명
LOCATION:테스트 장소
END:VEVENT
END:VCALENDAR"""

        # Act
        events = provider._parse_ics_content(
            sample_ics,
            datetime(2024, 1, 1, tzinfo=timezone.utc),
            datetime(2024, 1, 31, tzinfo=timezone.utc)
        )

        # Assert
        assert len(events) == 1
        event = events[0]
        assert event.title == "테스트 이벤트"
        assert event.description == "테스트 설명"
        assert event.location == "테스트 장소"

@pytest.mark.performance  
class TestPerformance:
    """성능 테스트"""

    @pytest.mark.asyncio
    async def test_monthly_view_performance(self, sync_service, db_session):
        """월 뷰 성능 테스트 (1000개 이벤트 중 월간 조회)"""
        # Arrange - 1000개 이벤트를 한 달에 고르게 분산
        user_id = "user_123"
        calendar_id = "cal_perf"
        
        events = []
        base_date = datetime(2024, 1, 1, tzinfo=timezone.utc)
        
        for i in range(1000):
            # 한 달 동안 랜덤하게 분산
            day_offset = (i * 43200) % (30 * 24 * 3600)  # 30일 내 분산
            event_time = base_date + timedelta(seconds=day_offset)
            
            event = Event(
                user_id=user_id,
                external_event_id=f"perf_evt_{i}",
                external_calendar_id=calendar_id,
                title=f"Performance Event {i}",
                start_datetime=event_time,
                end_datetime=event_time + timedelta(hours=1),
                source_platform="internal"
            )
            events.append(event)
        
        db_session.add_all(events)
        await db_session.commit()

        # Act - 월간 조회 (성능 측정)
        start_time = datetime.now()
        
        month_start = datetime(2024, 1, 1, tzinfo=timezone.utc)
        month_end = datetime(2024, 1, 31, 23, 59, 59, tzinfo=timezone.utc)
        
        monthly_events = await sync_service._get_events_in_range(
            user_id, month_start, month_end
        )
        
        end_time = datetime.now()

        # Assert
        query_time = (end_time - start_time).total_seconds()
        
        assert len(monthly_events) > 0  # 일부 이벤트 조회됨
        assert query_time < 0.1, f"Monthly query took {query_time}s, expected < 0.1s"

    @pytest.mark.asyncio
    async def test_rrule_expansion_performance(self):
        """RRULE 확장 성능 테스트"""
        from app.data.local.app_database import EventDao
        
        # Arrange - 주간 반복 이벤트
        base_event = Event(
            id="recurring_perf",
            calendar_id="cal_perf",
            title="Weekly Meeting",
            start_datetime=datetime(2024, 1, 1, 9, 0, tzinfo=timezone.utc),
            end_datetime=datetime(2024, 1, 1, 10, 0, tzinfo=timezone.utc),
            recurrence_rule="RRULE:FREQ=WEEKLY;BYDAY=MO",
            source_platform="internal"
        )

        dao = EventDao(None)  # DB 없이 순수 로직 테스트

        # Act - 1년간 확장 (약 52개 인스턴스)
        start_time = datetime.now()
        
        instances = dao._expand_rrule(
            base_event,
            datetime(2024, 1, 1, tzinfo=timezone.utc),
            datetime(2024, 12, 31, tzinfo=timezone.utc)
        )
        
        end_time = datetime.now()

        # Assert
        expansion_time = (end_time - start_time).total_seconds()
        
        assert len(instances) == 52  # 주간 반복, 1년 = 52주
        assert expansion_time < 0.01, f"RRULE expansion took {expansion_time}s, expected < 0.01s"

# 테스트 헬퍼 함수들
@pytest.fixture(scope="session")
def event_loop():
    """세션 범위 이벤트 루프"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

def pytest_configure(config):
    """pytest 설정"""
    config.addinivalue_line("markers", "performance: performance tests")
    config.addinivalue_line("markers", "integration: integration tests")

# Acceptance Criteria:
# - Provider mock으로 Google/Naver/Kakao 동기화 로직 단위 테스트 
# - 충돌 해결(Last-Write-Wins), 재시도, 백오프 정책 테스트
# - 1,000개 이벤트 배치 처리가 10초 이내 완료
# - 월간 뷰 쿼리가 0.1초 이내 응답
# - RRULE 확장이 0.01초 이내 완료