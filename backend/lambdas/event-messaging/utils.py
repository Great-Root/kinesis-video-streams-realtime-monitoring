import json

def to_json(obj):
    """객체를 JSON 문자열로 변환"""
    return json.dumps(obj, default=str)

def log_event(event):
    """Lambda 이벤트 로깅"""
    print(f"Received event: {to_json(event)}")
