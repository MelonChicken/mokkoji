# Mokkoji MVP - 일정/모임 통합 브리핑 앱

[![Flutter CI](https://github.com/MelonChicken/mokkoji/workflows/Flutter%20CI/badge.svg)](https://github.com/MelonChicken/mokkoji/actions?query=workflow%3A%22Flutter+CI%22)
[![PR Validation](https://github.com/MelonChicken/mokkoji/workflows/PR%20Validation/badge.svg)](https://github.com/MelonChicken/mokkoji/actions?query=workflow%3A%22PR+Validation%22)
[![Code Quality](https://github.com/MelonChicken/mokkoji/workflows/Code%20Quality/badge.svg)](https://github.com/MelonChicken/mokkoji/actions?query=workflow%3A%22Code+Quality%22)

Mokkoji는 다양한 플랫폼(카카오, 네이버, 구글 캘린더)의 일정을 통합하고, 스마트한 브리핑과 모임 관리 기능을 제공하는 Flutter 앱입니다.

## 🎯 주요 기능

### 📅 일정 통합 관리
- **멀티 플랫폼 동기화**: 카카오, 네이버, 구글 캘린더 통합
- **오프라인 우선**: 로컬 SQLite 캐시로 네트워크 없이도 동작
- **실시간 업데이트**: 변경사항 즉시 반영하는 반응형 UI
- **iCalendar 준수**: RFC 5545 표준 완전 지원

### 🤖 스마트 브리핑
- **일정 요약**: 오늘의 첫 일정부터 총 일정 수까지 간단 요약
- **지능형 알림**: 상황에 맞는 맞춤형 브리핑

### 👥 모임 관리
- **공유 일정**: 친구들과의 약속을 쉽게 생성 및 관리
- **협업 기능**: 모꼴지를 통한 효율적인 모임 계획

## 🏗️ 기술 아키텍처

### 📱 프론트엔드 (Flutter)
- **상태관리**: Riverpod 2.5.1
- **라우팅**: go_router 14.2.0
- **UI**: Material Design 3
- **동영상**: video_player 2.8.6

### 💾 데이터 계층
- **로컬 DB**: SQLite (sqflite 2.3.3)
- **캐싱 전략**: 오프라인 우선 + 백그라운드 동기화
- **데이터 모델**: iCalendar RFC 5545 준수

### 🔄 동기화 시스템
- **반응형 업데이트**: DB 신호 기반 실시간 UI 갱신
- **스마트 동기화**: 
  - 포그라운드 복귀 시 자동 동기화
  - 범위 변경 시 디바운스된 동기화 (500ms)
  - 백그라운드 주기적 동기화 (15분)
- **충돌 해결**: Last-Write-Wins 전략

## 📁 프로젝트 구조

```
lib/
├── app/                     # 앱 레벨 설정
│   └── app_lifecycle_sync.dart
├── db/                      # 데이터베이스 레이어
│   ├── app_database.dart    # SQLite 설정 및 마이그레이션
│   └── db_signal.dart       # 반응형 업데이트 시그널
├── features/
│   ├── calendar/            # 달력 기능
│   │   └── presentation/
│   │       └── day_events_consumer.dart
│   ├── events/              # 이벤트 관리
│   │   ├── data/           # 데이터 레이어
│   │   │   ├── event_entity.dart
│   │   │   ├── event_override_entity.dart
│   │   │   ├── events_dao.dart
│   │   │   ├── event_overrides_dao.dart
│   │   │   └── events_repository.dart
│   │   └── providers/      # 상태 관리
│   │       ├── events_providers.dart
│   │       ├── events_watch_provider.dart
│   │       └── debounced_sync_provider.dart
│   └── onboarding/         # 온보딩 화면
│       ├── onboarding_gate.dart
│       ├── onboarding_screen.dart
│       └── widgets/
│           └── onb_video_hero.dart
└── theme/                  # 테마 시스템
    ├── app_theme.dart
    └── tokens.dart
```

## 🚀 시작하기

### 필수 요구사항
- Flutter 3.3.0+
- Dart 3.0+

### 설치 및 실행
```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 💾 데이터베이스 스키마

### Events Table (version 2)
```sql
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  start_dt TEXT NOT NULL,          -- ISO8601 with timezone
  end_dt TEXT,
  all_day INTEGER NOT NULL,
  location TEXT,
  source_platform TEXT NOT NULL,   -- 'google' | 'naver' | 'kakao' | 'internal'
  platform_color TEXT,
  
  -- iCalendar RFC 5545 fields
  ical_uid TEXT,                   -- UID
  dtstamp TEXT,                    -- DTSTAMP
  sequence INTEGER,                -- SEQUENCE
  rrule TEXT,                      -- RRULE
  rdate_json TEXT,                 -- RDATE (JSON array)
  exdate_json TEXT,                -- EXDATE (JSON array)
  tzid TEXT,                       -- TZID
  transparency TEXT,               -- TRANSP
  url TEXT,                        -- URL
  categories_json TEXT,            -- CATEGORIES (JSON array)
  organizer_email TEXT,            -- ORGANIZER
  geo_lat REAL,                    -- GEO latitude
  geo_lng REAL,                    -- GEO longitude
  
  status TEXT,
  attendees_json TEXT,
  updated_at TEXT NOT NULL,
  deleted_at TEXT                  -- soft delete
);
```

### Event Overrides Table
```sql
CREATE TABLE event_overrides (
  id TEXT PRIMARY KEY,
  ical_uid TEXT NOT NULL,          -- parent event UID
  recurrence_id TEXT NOT NULL,     -- RECURRENCE-ID
  start_dt TEXT,
  end_dt TEXT,
  all_day INTEGER,
  title TEXT,
  description TEXT,
  location TEXT,
  status TEXT,
  attendees_json TEXT,
  last_modified TEXT NOT NULL
);
```

## 🔄 동기화 전략

### 자동 동기화 트리거
1. **앱 포그라운드 복귀**: 5분+ 경과 시 즉시 동기화
2. **달력 범위 변경**: 500ms 디바운스 후 동기화  
3. **백그라운드**: 15분 주기 동기화
4. **네트워크 재연결**: 즉시 동기화

### 반응형 UI 업데이트
- **DB 신호 시스템**: SQLite 변경 후 브로드캐스트
- **스트림 기반**: 실시간 UI 업데이트
- **메모리 효율**: auto-dispose로 자원 관리

## 🛠️ 개발 가이드

### 새로운 기능 추가
1. `lib/features/` 하위에 feature 디렉토리 생성
2. `data/`, `presentation/`, `providers/` 구조 따르기
3. Riverpod provider로 상태 관리
4. DB 변경 시 `DbSignal.instance.ping()` 호출

### 데이터베이스 마이그레이션
1. `app_database.dart`에서 `_dbVersion` 증가
2. `onUpgrade`에 DDL 스크립트 추가
3. `onCreate`에도 동일 스키마 반영

### CI/CD

GitHub Actions를 통한 자동화된 CI/CD 파이프라인:

- **Flutter CI**: 빌드, 테스트, 정적 분석
- **PR Validation**: PR 품질 체크, 번들 사이즈 분석
- **Code Quality**: 보안 스캔, 의존성 감사, 코드 메트릭스

상세 내용은 [.github/workflows/README.md](.github/workflows/README.md) 참조

### 커밋 메시지 규칙

[Conventional Commits](https://www.conventionalcommits.org/) 형식 준수:
```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 변경
style: 코드 포맷팅
refactor: 리팩토링
test: 테스트 추가/수정
chore: 빌드/설정 변경
```

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 🤝 기여

버그 리포트, 기능 요청, PR 환영합니다!

---

*🤖 이 프로젝트는 [Claude Code](https://claude.ai/code)를 활용하여 개발되었습니다.*
