"""사용자 인증 및 권한 관리

JWT 토큰 기반 인증 시스템
- 개발 단계에서는 단순화된 인증 사용
- 추후 OAuth2, JWT 등 확장 가능

"""
from typing import Dict, Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
import os

# Security scheme
security = HTTPBearer()

# JWT settings
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-here")
ALGORITHM = "HS256"

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict:
    """현재 사용자 정보 추출

    개발 단계에서는 단순화된 인증 사용
    추후 실제 JWT 토큰 검증으로 확장
    """
    try:
        # 개발 환경에서는 하드코딩된 사용자 반환
        if os.getenv("ENVIRONMENT") == "development":
            return {
                "sub": "test-user-uuid",
                "email": "test@mokkoji.com",
                "name": "테스트 사용자"
            }

        # 실제 JWT 토큰 검증 (프로덕션용)
        token = credentials.credentials
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_id: str = payload.get("sub")
            if user_id is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Could not validate credentials"
                )
            return payload
        except jwt.PyJWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials"
            )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )

def create_access_token(data: dict) -> str:
    """액세스 토큰 생성"""
    to_encode = data.copy()
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# 개발용 로그인 (실제 환경에서는 제거)
async def dev_login(email: str = "test@mokkoji.com") -> Dict:
    """개발 환경용 간단 로그인"""
    user_data = {
        "sub": "test-user-uuid",
        "email": email,
        "name": "테스트 사용자"
    }

    token = create_access_token(user_data)
    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user_data
    }