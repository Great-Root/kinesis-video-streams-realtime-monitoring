import boto3
import os

dynamodb = boto3.client("dynamodb")
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]

def save_connection(connection_id, user_id):
    """DynamoDB에 WebSocket 연결 정보 저장"""
    dynamodb.put_item(
        TableName=DYNAMODB_TABLE,
        Item={"connectionId": {"S": connection_id}, "userId": {"S": user_id}}
    )

def remove_connection(connection_id):
    """WebSocket 연결 해제 시 DynamoDB에서 삭제"""
    dynamodb.delete_item(
        TableName=DYNAMODB_TABLE,
        Key={"connectionId": {"S": connection_id}}
    )

def get_all_connection_ids():
    """DynamoDB에서 연결된 모든 사용자 가져오기"""
    response = dynamodb.scan(TableName=DYNAMODB_TABLE)
    return [item["connectionId"]["S"] for item in response.get("Items", [])]
