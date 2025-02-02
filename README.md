# Kinesis Video Streams - Real-Time Monitoring

## 프로젝트 개요

Kinesis Video Streams - Real-Time Monitoring은 AWS 기반 실시간 데이터 스트리밍 및 이벤트 메시징 시스템을 제공하는 프로젝트입니다. 이 시스템은 Kinesis Video Stream, Kinesis Data Stream, Rekognition(Face Detect), API Gateway (WebSocket), Lambda 등을 활용하여 실시간 영상 모니터링 및 이벤트 분석 기능을 수행합니다.

## 주요 기능

- **실시간 비디오 스트리밍**: 로컬 또는 EC2에서 Kinesis Video Stream으로 영상 송출
- **실시간 영상 분석**: AWS Rekognition을 활용한 객체 탐지 및 분석
- **이벤트 메시징**: Kinesis Data Stream을 활용한 실시간 데이터 전송 및 처리
- **푸시 알림**: API Gateway (WebSocket)과 Lambda를 활용한 사용자 실시간 알림 전송
- **실시간 웹 프론트엔드**: S3 + CloudFront 기반 정적 웹 호스팅 및 실시간 모니터링 UI 제공
- **인증 및 보안**: AWS Cognito 및 IAM 인증 방식 적용

## 디렉토리 구조

프로젝트는 다음과 같은 디렉토리 구조로 구성됩니다.

```
root/
├── backend/                   # 백엔드 Lambda 코드
│   └── lambdas/
│       └── event-messaging/    # 이벤트 메시징 관련 Lambda 함수
├── frontend/                   # 프론트엔드 React 애플리케이션
│   ├── README.md
│   ├── package-lock.json
│   ├── package.json
│   ├── public/
│   ├── src/
│   │   ├── App.js
│   │   ├── WebSocketClient.js
│   │   ├── VideoStream.js
│   │   ├── viewer.js
├── terraform/
│   ├── environments/           # 환경별 설정 파일
│   │   ├── dev.tfvars          # 개발 환경 변수 파일
│   │   ├── staging.tfvars      # 스테이징 환경 변수 파일
│   │   ├── prod.tfvars         # 운영 환경 변수 파일
│   ├── backend.tf
│   ├── main.tf
│   ├── modules/
│   │   ├── event-messaging
│   │   ├── frontend-hosting
│   │   ├── network-infrastructure
│   │   ├── video-processing
│   │   ├── video-streaming-ec2
│   ├── outputs.tf
│   ├── terraform.tfvars
│   ├── variables.tf
├── apply.sh                    # Terraform 배포 스크립트
├── destroy.sh                   # Terraform 리소스 삭제 스크립트
├── init.sh                      # 프로젝트 초기화 스크립트
```

## 요구 사항

- **AWS CLI** 설치 및 인증 설정
- **Terraform 1.9+** 버전 사용
- **Node.js 18+** (프론트엔드 개발 시 필요)

## 프로젝트 초기화 (`init.sh`)

프로젝트를 처음 설정할 때 `init.sh` 스크립트를 실행하면 환경 설정 및 필요한 AWS 리소스(S3 버킷, DynamoDB 테이블 등)가 자동으로 생성됩니다.

```sh
bash init.sh
```

스크립트 실행 중 `환경(Environment)`을 선택하면 해당 환경에 맞는 설정 파일이 생성되며, Terraform 초기화가 수행됩니다.

### 1. `init.sh` 주요 기능

- **Terraform 환경별 설정 초기화**: 환경(`dev`, `staging`, `prod`)을 선택하여 `.tfvars` 파일을 자동으로 생성합니다.

- **AWS S3 버킷 생성**: Terraform 상태 파일을 저장할 S3 버킷을 자동으로 생성합니다.

- **DynamoDB 테이블 생성**: Terraform 상태 잠금을 위한 DynamoDB 테이블을 생성합니다.

- **Terraform Backend 구성**: 생성된 S3 및 DynamoDB 정보를 사용하여 `backend.tf` 파일을 동적으로 생성합니다.

- **Terraform 초기화 실행**: `terraform init`를 실행하여 backend 구성을 적용합니다.

-

## Terraform 배포 및 관리

### 1. Terraform 배포 (`apply.sh`)

Terraform을 사용하여 AWS 인프라를 배포할 수 있습니다. `apply.sh` 스크립트를 사용하면 환경별로 자동으로 배포됩니다.

```sh
bash apply.sh {환경}  # 예: dev, staging, prod
```

위 명령어를 실행하면 해당 환경에 맞는 `terraform.tfvars` 파일을 자동으로 로드하고 배포가 수행됩니다.

### 2. Terraform 리소스 삭제 (`destroy.sh`)

배포된 AWS 인프라를 삭제하려면 `destroy.sh` 스크립트를 실행하면 됩니다.

```sh
bash destroy.sh {환경}  # 예: dev, staging, prod
```

이 명령어는 해당 환경의 Terraform 리소스를 삭제하며, 삭제 전 사용자 확인을 요구합니다.

## 로컬 개발 방법

### 1. 프론트엔드 실행 방법

React 기반 프론트엔드는 다음 명령어를 사용하여 실행할 수 있습니다.

```sh
cd frontend
npm install  # 필요한 패키지 설치
npm start    # 개발 서버 실행
```

### 2. 환경변수 설정 (.env)

React 애플리케이션은 `.env` 파일에서 환경변수를 로드합니다. 아래 예제를 참고하여 `.env` 파일을 설정하세요.

> **참고:** Terraform 배포 시 `.env` 파일이 자동 생성됩니다.

```sh
REACT_APP_WEBSOCKET_API_URL=wss://your-api-gateway-url
REACT_APP_KINESIS_STREAM_NAME=your-kinesis-stream-name
```

### 3. AWS 서비스 상세 설명

#### API Gateway (WebSocket)

- 실시간 이벤트 메시지를 처리하며, Lambda와 연계되어 클라이언트에게 WebSocket을 통해 알림을 전송합니다.
- 사용자는 브라우저에서 WebSocket을 연결하여 실시간 데이터를 받을 수 있습니다.

#### Kinesis Video Stream

- 비디오 데이터를 AWS 클라우드에 실시간으로 스트리밍합니다.
- `video-streaming-ec2` 모듈 또는 로컬에서 영상을 송출할 수 있습니다.

#### Rekognition

- AWS Rekognition을 활용하여 비디오 스트림에서 얼굴을 감지하고 분석합니다.
- 감지된 이벤트는 API Gateway를 통해 프론트엔드에 전달됩니다.

#### 라이선스

- 이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](./LICENSE) 파일을 참고하세요.
