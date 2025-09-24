"""데이터베이스 연결 및 세션 관리

PostgreSQL AsyncPG를 사용한 비동기 데이터베이스 연결
- 환경 변수에서 DATABASE_URL 읽기
- AsyncSession 의존성 주입
- 연결 풀링 및 최적화

"""
import os
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

# Database URL from environment
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://user:password@localhost/mokkoji_db"
)

# Create async engine
engine = create_async_engine(
    DATABASE_URL,
    echo=False,  # Set to True for SQL logging in development
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    pool_recycle=3600,
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Dependency for FastAPI
async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """AsyncSession 의존성 주입"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

# Database base for models
Base = declarative_base()

# Database lifecycle functions
async def init_db():
    """데이터베이스 초기화 (테이블 생성)"""
    async with engine.begin() as conn:
        # Import all models to ensure they're registered
        from ..models.event_models import Calendar, Event, EventOverride, Attendee
        from ..models.sync_models import SyncState, ExternalConnection

        # Create all tables
        await conn.run_sync(Base.metadata.create_all)

async def close_db():
    """데이터베이스 연결 종료"""
    await engine.dispose()