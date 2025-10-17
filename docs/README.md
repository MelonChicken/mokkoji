# Mokkoji 문서

모꼬지 프로젝트의 모든 기술 문서는 이 디렉토리에서 관리됩니다.

## 📁 디렉토리 구조

```
docs/
├── architecture/          # 시스템 아키텍처 및 설계 문서
├── features/             # 기능 구현 상세 문서
├── technical-issues/     # 기술적 이슈 및 해결 방법
└── project-management/   # 프로젝트 관리 및 리포트
```

## 📚 문서 카테고리

### Architecture (아키텍처)
시스템 설계, 데이터 흐름, 아키텍처 패턴에 대한 문서

- **CONSISTENCY_IMPLEMENTATION.md** - 일정 일관성 보장 시스템
  - 단일 진실 원천 (Single Source of Truth) 아키텍처
  - 단일 스트림을 통한 실시간 데이터 동기화
  - KST 기준 통일 및 즉시 반영 메커니즘

- **CONSISTENCY_UPGRADE.md** - 스트림 안정화 업그레이드
  - DateKey 값 객체를 통한 안정적 스트림 파라미터
  - keepAlive + broadcast로 재구독 방지
  - 디버그 도구 및 로깅 시스템

- **REALTIME_EVENTS_README.md** - 실시간 이벤트 수집 시스템
  - 실시간 UI 업데이트 아키텍처
  - 타임존 일관성 및 스트림 기반 설계
  - 효율적인 upsert 작업

### Features (기능)
주요 기능의 구현 상세 및 사용법

- **REPEAT_IMPLEMENTATION_SUMMARY.md** - 반복 일정 구현
  - RRULE 기반 인스턴스 구체화 (materialization)
  - 매일/매주/매월 반복 패턴 지원
  - KST 기준 occurrence 생성 및 관리

- **ENHANCED_DETAIL_USAGE.md** - 향상된 상세 화면
  - 인라인 편집 기능
  - 바텀시트 제거 및 UX 개선
  - 반복 설정 UI

- **VOICE_EVENT_MODIFICATION.md** - 음성 일정 수정 (v1)
  - OpenAI 함수 호출 통합
  - STT → 함수 호출 → DB 업데이트 파이프라인
  - FastAPI 서버 AI 엔드포인트

### Technical Issues (기술 이슈)
기술적 문제 해결 및 시스템 개선 사항

- **TIMEZONE_HANDLING.md** - 타임존 처리 통합 가이드
  - KST 강제 표시 시스템
  - UTC 저장 규약 및 ISO 파싱
  - 데이터베이스 마이그레이션
  - 자정 경계 처리 및 엣지 케이스

### Project Management (프로젝트 관리)
코드 정리, 리팩토링, 프로젝트 관리 리포트

- **POLISHING_REPORT.md** - Canonical 통합 리포트
  - 중복 파일 제거 및 통합
  - 표준 구현 선정
  - CI 가드레일 설정

## 🎯 문서 사용 가이드

### 새로운 기능 개발 시
1. `architecture/` - 시스템 설계 패턴 참고
2. `features/` - 유사 기능의 구현 예제 확인
3. 구현 완료 후 `features/`에 문서 작성

### 기술적 문제 해결 시
1. `technical-issues/` - 유사 문제 해결 사례 검색
2. 해결 방법 문서화 후 추가

### 코드 정리 및 리팩토링 시
1. `project-management/` - 기존 정리 리포트 참고
2. 작업 완료 후 리포트 작성

## 📝 문서 작성 규칙

### 파일명
- 영문 대문자 + 언더스코어 사용
- 명확하고 설명적인 이름
- 예: `FEATURE_NAME_IMPLEMENTATION.md`

### 문서 구조
```markdown
# 제목

## 개요
간단한 요약

## 주요 내용
상세 설명

## 사용법 / 구현 방법
실용적인 가이드

## 참고사항
추가 정보
```

### 언어
- 한국어 우선 (기술 용어는 영문 병기)
- 코드 예제는 주석을 한국어로

## 🔗 관련 문서

프로젝트 루트의 주요 문서:
- `README.md` - 프로젝트 전체 개요
- `CONTRIBUTING.md` - 기여 가이드 (예정)

## 📧 문의

문서 관련 문의사항은 이슈로 등록해주세요.
