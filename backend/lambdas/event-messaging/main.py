import json
import logging
from websocket_events import handle_websocket_event
from kinesis_events import handle_kinesis_event

# 🔹 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def lambda_handler(event, context):
    """Lambda 엔트리포인트 (WebSocket + Kinesis 이벤트 라우팅)"""
    logger.info("🔹 Lambda 함수 실행됨")
    logger.debug(f"📥 수신된 이벤트: {json.dumps(event, indent=2)}")

    # WebSocket 이벤트 처리
    if "requestContext" in event and "routeKey" in event["requestContext"]:
        logger.info(f"🔗 WebSocket 이벤트 라우팅: {event['requestContext']['routeKey']}")
        return handle_websocket_event(event)

    # Kinesis 이벤트 처리
    if "Records" in event and "kinesis" in event["Records"][0]:
        logger.info("📡 Kinesis 이벤트 감지됨")
        return handle_kinesis_event(event)

    logger.warning("⚠️ 알 수 없는 이벤트 유형")
    return {"statusCode": 400, "body": "Unknown event"}
