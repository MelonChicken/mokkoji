"""Security utilities for token encryption and decryption

설계 의도:
- AES-256-GCM으로 OAuth 토큰 암호화하여 DB 저장
- AAD(Additional Authenticated Data)로 connection_id 사용하여 토큰 재사용 방지
- 32바이트 키, 12바이트 nonce 사용으로 보안 강화

"""
import os
import base64
from typing import Tuple
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import logging

logger = logging.getLogger(__name__)

# 전역 암호화 키 (환경변수에서 로드)
_ENCRYPTION_KEY: bytes = None
_KEY_SALT: bytes = None

def _get_encryption_key() -> bytes:
    """암호화 키 가져오기 (지연 초기화)"""
    global _ENCRYPTION_KEY, _KEY_SALT
    
    if _ENCRYPTION_KEY is None:
        # 환경변수에서 마스터 키 로드
        master_key = os.getenv('MOKKOJI_MASTER_KEY')
        if not master_key:
            raise ValueError("MOKKOJI_MASTER_KEY environment variable not set")
        
        # Salt 로드 (없으면 생성)
        salt_b64 = os.getenv('MOKKOJI_KEY_SALT')
        if salt_b64:
            _KEY_SALT = base64.b64decode(salt_b64)
        else:
            _KEY_SALT = os.urandom(16)
            logger.warning("Generated new salt. Set MOKKOJI_KEY_SALT environment variable for production.")
        
        # PBKDF2로 32바이트 키 유도
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=_KEY_SALT,
            iterations=100000,
        )
        _ENCRYPTION_KEY = kdf.derive(master_key.encode())
    
    return _ENCRYPTION_KEY

async def encrypt_token(plaintext: str, connection_id: str) -> str:
    """
    OAuth 토큰을 AES-256-GCM으로 암호화
    
    Args:
        plaintext: 암호화할 토큰 문자열
        connection_id: AAD로 사용할 연결 ID
        
    Returns:
        base64 인코딩된 암호화 결과 (nonce + ciphertext + tag)
    """
    try:
        key = _get_encryption_key()
        aesgcm = AESGCM(key)
        
        # 12바이트 nonce 생성
        nonce = os.urandom(12)
        
        # AAD로 connection_id 사용 (토큰 재사용 방지)
        aad = connection_id.encode('utf-8')
        
        # 암호화 (nonce + ciphertext + 16바이트 tag)
        ciphertext = aesgcm.encrypt(nonce, plaintext.encode('utf-8'), aad)
        
        # nonce + ciphertext를 base64로 인코딩
        encrypted_data = nonce + ciphertext
        return base64.b64encode(encrypted_data).decode('ascii')
        
    except Exception as e:
        logger.error(f"Token encryption failed: {e}")
        raise ValueError("Failed to encrypt token")

async def decrypt_token(encrypted_data: str, connection_id: str) -> str:
    """
    암호화된 토큰을 복호화
    
    Args:
        encrypted_data: base64 인코딩된 암호화 데이터
        connection_id: AAD로 사용된 연결 ID
        
    Returns:
        복호화된 토큰 문자열
    """
    try:
        key = _get_encryption_key()
        aesgcm = AESGCM(key)
        
        # base64 디코딩
        raw_data = base64.b64decode(encrypted_data)
        
        # nonce (12바이트) 추출
        nonce = raw_data[:12]
        ciphertext = raw_data[12:]
        
        # AAD로 connection_id 사용
        aad = connection_id.encode('utf-8')
        
        # 복호화
        plaintext = aesgcm.decrypt(nonce, ciphertext, aad)
        return plaintext.decode('utf-8')
        
    except Exception as e:
        logger.error(f"Token decryption failed: {e}")
        raise ValueError("Failed to decrypt token")

def generate_salt() -> str:
    """새 salt 생성 (설정용)"""
    salt = os.urandom(16)
    return base64.b64encode(salt).decode('ascii')

async def validate_encryption_setup() -> bool:
    """암호화 설정 검증"""
    try:
        test_data = "test_token_12345"
        test_connection_id = "conn_test_id"
        
        # 암호화/복호화 테스트
        encrypted = await encrypt_token(test_data, test_connection_id)
        decrypted = await decrypt_token(encrypted, test_connection_id)
        
        if decrypted != test_data:
            logger.error("Encryption validation failed: data mismatch")
            return False
        
        # 잘못된 connection_id로 복호화 시도 (실패해야 함)
        try:
            await decrypt_token(encrypted, "wrong_connection_id")
            logger.error("Encryption validation failed: AAD bypass")
            return False
        except ValueError:
            # 예상된 실패
            pass
        
        logger.info("Encryption setup validated successfully")
        return True
        
    except Exception as e:
        logger.error(f"Encryption validation error: {e}")
        return False

class TokenEncryptionError(Exception):
    """토큰 암호화 관련 오류"""
    pass

# 유틸리티 함수들
async def encrypt_refresh_token(refresh_token: str, connection_id: str) -> str:
    """Refresh token 암호화 (별칭)"""
    return await encrypt_token(refresh_token, connection_id)

async def decrypt_refresh_token(encrypted_data: str, connection_id: str) -> str:
    """Refresh token 복호화 (별칭)"""
    return await decrypt_token(encrypted_data, connection_id)

def mask_token_for_logging(token: str, visible_chars: int = 8) -> str:
    """로깅용 토큰 마스킹"""
    if not token or len(token) <= visible_chars:
        return "***"
    
    return token[:visible_chars] + "..." + "*" * (len(token) - visible_chars)

# Acceptance Criteria:
# - AES-256-GCM으로 OAuth access/refresh 토큰 안전하게 암호화
# - connection_id를 AAD로 사용하여 토큰 재사용 공격 방지
# - 환경변수 기반 키 관리로 설정 분리
# - 암호화 설정 검증 함수로 시스템 무결성 확인
# - 로깅 시 토큰 마스킹으로 민감정보 보호