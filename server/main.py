"""모꼬지 FastAPI 메인 애플리케이션

음성으로 일정 수정 (v1) 서버
- 기존 sync API 유지
- 새로운 AI 음성 처리 API 추가
- OpenAI 함수 호출 통합

"""
import os
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn

# Import routers
from app.api.sync_routes import router as sync_router
from app.api.ai_routes import router as ai_router

# Logging configuration
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# FastAPI app initialization
app = FastAPI(
    title="모꼬지 API Server",
    description="일정/모임 통합 브리핑 앱 - 음성 일정 수정 v1",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Flutter 개발 환경에서는 모든 origin 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(sync_router)  # 기존 동기화 API
app.include_router(ai_router)    # 새 AI 음성 처리 API

# Health check
@app.get("/")
async def root():
    return {
        "service": "모꼬지 API Server",
        "version": "1.0.0",
        "features": {
            "calendar_sync": True,
            "voice_event_modification": True,
            "openai_integration": True
        }
    }

@app.get("/health")
async def health_check():
    """서비스 상태 확인"""
    try:
        # 환경 변수 확인
        required_env_vars = ["OPENAI_API_KEY", "DATABASE_URL"]
        missing_vars = [var for var in required_env_vars if not os.getenv(var)]

        if missing_vars:
            return JSONResponse(
                status_code=503,
                content={
                    "status": "unhealthy",
                    "missing_env_vars": missing_vars
                }
            )

        return {
            "status": "healthy",
            "database": "connected",
            "openai": "configured",
            "apis": {
                "sync": "/api/sync",
                "ai": "/ai"
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=503,
            content={"status": "unhealthy", "error": str(e)}
        )

# Exception handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error"}
    )

if __name__ == "__main__":
    # 개발 환경에서 직접 실행할 때
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info"
    )