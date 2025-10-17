# 모꼬지 음성 일정 수정 (v1) 마이그레이션 가이드

## 개요
이 문서는 모꼜지 앱에 "음성으로 일정 수정 (v1)" 기능을 추가하는 구현 과정과 변경사항을 기록합니다.

## 구현 목표
- **LangChain 없이** OpenAI 함수 호출 직접 사용
- FastAPI 서버에 AI 엔드포인트 추가
- 음성 파일 업로드 → STT → 함수 호출 → 데이터베이스 작업 파이프라인
- 기존 PostgreSQL events 스키마와 완전 호환

## 주요 변경사항

### 1. 서버 측 구현 (FastAPI)

#### 새로 추가된 파일들:
```
server/
├── main.py                    # FastAPI 메인 애플리케이션
├── requirements.txt           # Python 의존성
├── app/
│   ├── api/ai_routes.py      # AI 음성 처리 엔드포인트
│   ├── core/
│   │   ├── database.py       # PostgreSQL AsyncPG 연결
│   │   └── auth.py           # JWT 기반 인증 (개발용 단순화)
│   └── models/
│       ├── event_models.py   # Events/Calendars SQLAlchemy 모델
│       └── sync_models.py    # 동기화 상태 모델
```

#### 새로운 REST API 엔드포인트:
1. **POST /ai/find_event** - 이벤트 검색
   ```json
   {
     "query": "미팅",
     "start_date": "2025-01-20",
     "end_date": "2025-01-21"
   }
   ```

2. **POST /ai/reschedule** - 일정 시간 변경
   ```json
   {
     "event_id": "uuid",
     "new_start_utc": "2025-01-20T10:00:00Z",
     "new_end_utc": "2025-01-20T11:00:00Z"
   }
   ```

3. **POST /ai/update_fields** - 일정 내용 수정
   ```json
   {
     "event_id": "uuid",
     "title": "새 제목",
     "description": "새 설명",
     "location": "새 위치"
   }
   ```

4. **POST /ai/cancel** - 일정 취소
   ```json
   {
     "event_id": "uuid",
     "cancel_scope": "single"
   }
   ```

5. **GET /ai/check_conflicts** - 충돌 확인
   ```
   ?start_utc=2025-01-20T10:00:00Z&end_utc=2025-01-20T11:00:00Z
   ```

#### 추가 AI 기능 엔드포인트:
- **POST /ai/transcribe** - 음성 파일을 텍스트로 변환 (Whisper)
- **POST /ai/process_voice** - 음성 명령 종합 처리 (STT + 함수 호출)

### 2. OpenAI 함수 호출 통합

#### 함수 정의:
- `find_event`: 이벤트 검색
- `reschedule_event`: 시간 변경
- `update_event_fields`: 내용 수정
- `cancel_event`: 일정 취소
- `check_conflicts`: 충돌 확인

#### 처리 흐름:
```
음성 파일 업로드 → Whisper STT → OpenAI 함수 호출 → REST API 실행 → DB 업데이트
```

### 3. 중복 파일 정리

#### 삭제된 파일:
- `lib/screens/detail_screen.dart` → `enhanced_detail_screen.dart`로 통합됨

#### 유지된 파일:
- `lib/screens/enhanced_detail_screen.dart` (현재 활성화된 detail screen)
- `lib/screens/show_enhanced_detail.dart` (helper function)

### 4. 데이터베이스 호환성

#### 기존 schema.drift와 완전 호환:
```sql
-- events 테이블 구조 그대로 사용
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  calendar_id TEXT NOT NULL,
  title TEXT NOT NULL,
  start_utc INTEGER NOT NULL,  -- Unix timestamp
  end_utc INTEGER,
  all_day INTEGER DEFAULT 0,
  location TEXT,
  recurrence_rule TEXT,
  deleted INTEGER DEFAULT 0,
  sync_status TEXT DEFAULT 'synced'
);
```

## 설정 요구사항

### 환경 변수:
```bash
# OpenAI API 키 (필수)
OPENAI_API_KEY=sk-...

# 데이터베이스 연결 (PostgreSQL)
DATABASE_URL=postgresql+asyncpg://user:password@localhost/mokkoji_db

# JWT 시크릿 (개발용)
JWT_SECRET_KEY=your-secret-key

# 개발 환경 플래그
ENVIRONMENT=development
```

### Python 의존성 설치:
```bash
cd server
pip install -r requirements.txt
```

### 서버 실행:
```bash
cd server
python main.py
```

## 기능 테스트

### 1. 음성 명령 예시:
- "내일 오후 2시 미팅을 3시로 변경해줘"
- "회의 제목을 '중요한 미팅'으로 바꿔줘"
- "오늘 저녁 약속 취소해줘"
- "내일 10시부터 11시까지 시간 비어있나?"

### 2. API 테스트:
```bash
# Health check
curl http://localhost:8000/ai/health

# 음성 처리 (텍스트 버전)
curl -X POST http://localhost:8000/ai/process_voice \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{"user_message": "내일 미팅 시간 변경해줘"}'
```

## 파일 트리 변경사항

### 변경 전:
```
mokkoji/
├── lib/screens/
│   ├── detail_screen.dart         (763 lines - 구버전)
│   ├── enhanced_detail_screen.dart (619 lines - 신버전)
│   └── show_enhanced_detail.dart
└── server/
    └── (기존 동기화 API만 존재)
```

### 변경 후:
```
mokkoji/
├── lib/screens/
│   ├── enhanced_detail_screen.dart (유지 - 활성 버전)
│   └── show_enhanced_detail.dart   (유지)
├── server/
│   ├── main.py                    (신규)
│   ├── requirements.txt           (신규)
│   └── app/
│       ├── api/
│       │   ├── ai_routes.py       (신규 - AI 엔드포인트)
│       │   └── sync_routes.py     (기존)
│       ├── core/
│       │   ├── database.py        (신규)
│       │   └── auth.py            (신규)
│       └── models/
│           ├── event_models.py    (신규)
│           └── sync_models.py     (신규)
└── docs/
    └── MIGRATION.md               (신규 - 이 문서)
```

## 향후 확장 계획

### Phase 2 개선사항:
1. **실시간 대화형 AI**: 연속 대화 지원
2. **고급 자연어 처리**: 복잡한 시간 표현 인식
3. **충돌 해결**: 자동 대안 시간 제시
4. **다국어 지원**: 영어, 일본어 음성 명령
5. **반복 일정 처리**: RRULE 기반 패턴 수정

### 성능 최적화:
- Redis 캐싱으로 응답 시간 단축
- 데이터베이스 연결 풀 최적화
- 배치 처리로 동시 요청 처리

## 주의사항

1. **보안**: 프로덕션에서는 실제 JWT 인증 구현 필요
2. **비용**: OpenAI API 사용량 모니터링 필요
3. **오류 처리**: 음성 인식 실패시 fallback UI 제공
4. **데이터 무결성**: 중요 일정 변경시 확인 단계 추가

## 트러블슈팅

### 자주 발생하는 문제:
1. **OpenAI API 키 오류**: `.env` 파일 확인
2. **데이터베이스 연결 실패**: PostgreSQL 서비스 상태 확인
3. **함수 호출 실패**: 사용자 메시지가 너무 모호한 경우
4. **권한 오류**: JWT 토큰 또는 사용자 ID 확인

---
*구현 완료일: 2025-01-20*
*담당자: Claude Code Agent*