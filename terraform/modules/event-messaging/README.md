# Terraform Module: Event Messaging

## 📌 개요

이 Terraform 모듈은 AWS WebSocket API Gateway와 Lambda, DynamoDB, Kinesis Data Stream을 활용한 이벤트 메시징 시스템을 구성합니다. Cognito 인증을 사용하여 보안을 강화하고, Kinesis와 Lambda를 통해 실시간 이벤트 처리를 지원합니다.

## 🚀 배포 리소스

### ✅ 주요 AWS 리소스

- **Lambda (`event-messaging-lambda`)**: WebSocket 및 Kinesis 이벤트를 처리하는 함수
- **DynamoDB (`websocket-connections`)**: WebSocket 연결 정보를 저장하는 테이블
- **API Gateway WebSocket**: 실시간 메시지 전송을 위한 WebSocket API
- **IAM Role & Policy**: Lambda 및 API Gateway에 필요한 권한 설정

## 📂 파일 구조

```
.
├── main.tf          # 주요 리소스 정의 (Lambda, API Gateway, DynamoDB)
├── outputs.tf       # 출력 변수 정의
├── variables.tf     # 입력 변수 정의
```

## 🔧 변수 설정 (`variables.tf`)

| 변수명                 | 설명                           |
| ---------------------- | ------------------------------ |
| `project_name`         | 프로젝트 이름                  |
| `region`               | AWS 리전                       |
| `environment`          | 배포 환경 (dev, staging, prod) |
| `kinesis_stream_arn`   | Kinesis Data Stream ARN        |
| `cognito_user_pool_id` | Cognito User Pool ID           |
| `cognito_client_id`    | Cognito App Client ID          |

## 📤 출력 변수 (`outputs.tf`)

| 변수명                 | 설명                           |
| ---------------------- | ------------------------------ |
| `lambda_function_name` | 생성된 Lambda 함수 이름        |
| `websocket_api_url`    | WebSocket API Gateway 호출 URL |
| `websocket_api_arn`    | WebSocket API Gateway ARN      |
| `dynamodb_table_name`  | DynamoDB 테이블 이름           |
