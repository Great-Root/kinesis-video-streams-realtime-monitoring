import json
import logging
import base64
from websocket_manager import send_websocket_message
from dynamo_manager import get_all_connection_ids

# 🔹 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def handle_kinesis_event(event):
    """Kinesis Rekognition 이벤트 처리 및 WebSocket 메시지 전송"""
    logger.info("📡 Kinesis 이벤트 처리 시작됨")
    logger.debug(f"📥 Kinesis 이벤트 데이터: {json.dumps(event, indent=2)}")

    ListOfNames = []

    for record in event['Records']:
        data = json.loads(base64.b64decode(record['kinesis']['data']).decode('ascii'))
        logger.debug(f"🔎 디코딩된 Kinesis 데이터: {json.dumps(data, indent=2)}")

        for response in data.get('FaceSearchResponse', []):
            for matchedface in response.get('MatchedFaces', []):
                face = matchedface.get('Face', {})
                imageId = face.get('ExternalImageId')

                if imageId:
                    logger.info(f"✅ 감지된 얼굴: {imageId}")
                    ListOfNames.append(imageId)

    if not ListOfNames:
        logger.info("⚠️ 감지된 얼굴 없음, 메시지 전송 생략")
        return {'statusCode': 200, 'body': "No face detected"}

    connections = get_all_connection_ids()
    message = {"message": f"Recognized faces: {', '.join(ListOfNames)}"}
    logger.info(f"📤 WebSocket 메시지 전송 시작 ({len(connections)}명의 사용자)")

    for connection_id in connections:
        send_websocket_message(connection_id, message)

    logger.info("✅ 모든 사용자에게 메시지 전송 완료")
    return {'statusCode': 200, 'body': "Message sent"}
