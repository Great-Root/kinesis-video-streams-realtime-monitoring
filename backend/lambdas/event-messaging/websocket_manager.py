import json
import logging
import boto3
import os

# 🔹 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

apigateway = boto3.client("apigatewaymanagementapi", endpoint_url=os.environ["WEBSOCKET_ENDPOINT"])

def send_websocket_message(connection_id, message):
    """WebSocket 클라이언트에게 메시지 전송"""
    try:
        logger.info(f"📤 WebSocket 메시지 전송: {connection_id}")
        apigateway.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps(message)
        )
        logger.info(f"✅ 메시지 전송 완료 (Connection ID: {connection_id})")
    except Exception as e:
        logger.error(f"❌ 메시지 전송 실패 (Connection ID: {connection_id}): {str(e)}")
