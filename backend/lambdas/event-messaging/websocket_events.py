import logging
import os
import json
import jwt  # PyJWT 필요 (Lambda Layers 또는 requirements.txt)
from dynamo_manager import save_connection, remove_connection

# 🔹 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_user_from_token(token):
    """Cognito 토큰에서 사용자 ID 추출"""
    try:
        decoded_token = jwt.decode(token, options={"verify_signature": False})  # 🔹 Cognito JWT 디코딩
        logger.info(f"✅ JWT 디코딩 성공 (사용자 ID: {decoded_token.get('sub')})")
        return decoded_token.get("sub")  # Cognito User ID 반환
    except Exception as e:
        logger.error(f"❌ JWT 디코딩 실패: {e}")
        return None

def handle_websocket_event(event):
    """WebSocket 연결/해제 처리"""
    connection_id = event["requestContext"]["connectionId"]
    route = event["requestContext"]["routeKey"]
    logger.info(f"🔗 WebSocket 이벤트 발생: {route} (Connection ID: {connection_id})")

    # 🔹 Authorization 값을 헤더 또는 쿼리스트링에서 가져오기
    headers = event.get("headers", {})
    query_params = event.get("queryStringParameters", {})

    auth_token = headers.get("Authorization") or query_params.get("Authorization")  # ✅ 헤더 & 쿼리스트링 체크
    logger.debug(f"🔑 Authorization 값: {auth_token}")

    if route == "$connect":
        if not auth_token:
            logger.warning("⚠️ Authorization 토큰 없음")
            return {"statusCode": 401, "body": "Unauthorized"}

        # 🔹 JWT 검증 수행
        user_id = get_user_from_token(auth_token)
        if not user_id:
            logger.warning("⚠️ 잘못된 JWT 토큰")
            return {"statusCode": 403, "body": "Invalid token"}

        save_connection(connection_id, user_id)
        logger.info(f"✅ WebSocket 연결 완료 (User: {user_id})")
        return {"statusCode": 200, "body": "Connected"}

    elif route == "$disconnect":
        remove_connection(connection_id)
        logger.info(f"❌ WebSocket 연결 해제됨 (Connection ID: {connection_id})")
        return {"statusCode": 200}

    logger.warning("⚠️ 알 수 없는 WebSocket 이벤트")
    return {"statusCode": 400, "body": "Invalid request"}
