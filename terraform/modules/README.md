# Terraform 모듈 개요

## 📌 소개

이 문서는 이 프로젝트에서 사용되는 Terraform 모듈에 대한 개요를 제공합니다. 인프라는 유지보수성과 확장성을 높이기 위해 모듈화되어 있으며, 각 모듈은 특정 역할을 수행하도록 설계되었습니다.

## 📂 모듈 구조

```
📂 modules
 ┣ 📂 frontend-hosting        # 정적 웹사이트 호스팅 (S3 + CloudFront)
 ┣ 📂 video-processing        # 비디오 스트리밍 및 분석 (Kinesis Video Stream + Rekognition)
 ┣ 📂 event-messaging         # WebSocket API Gateway 기반 이벤트 메시징
 ┣ 📂 network-infrastructure  # VPC, 서브넷 및 보안 그룹 설정
 ┗ 📂 video-streaming-ec2     # EC2 기반 비디오 스트리밍 시뮬레이션
```

## 🛠 모듈 설명

### 1️⃣ **frontend-hosting**

- **목적:** S3 및 CloudFront를 활용한 정적 React 프론트엔드 호스팅
- **사용 AWS 서비스:**
  - Amazon S3 (정적 웹사이트 호스팅)
  - Amazon CloudFront (CDN을 통한 글로벌 배포)
- **주요 기능:**
  - HTTPS 기반 보안 호스팅
  - 빠른 콘텐츠 제공을 위한 CDN 적용
  - 환경별 배포 지원
  - WAF 및 Geo 기반 접근 제어 지원

### 2️⃣ **video-processing**

- **목적:** Kinesis Video Stream을 통한 실시간 비디오 수집 및 Rekognition을 활용한 얼굴 인식
- **사용 AWS 서비스:**
  - Amazon Kinesis Video Stream (실시간 비디오 스트리밍)
  - Amazon Rekognition (얼굴 탐지 및 분석)
  - Amazon Kinesis Data Stream (비디오 분석 데이터 처리)
- **주요 기능:**
  - 실시간 비디오 분석 기능 제공
  - 확장 가능한 비디오 수집 및 보안 강화
  - Rekognition 기반 머신러닝 분석 연동 가능

### 3️⃣ **event-messaging**

- **목적:** WebSocket API Gateway를 활용한 실시간 이벤트 메시징 처리
- **사용 AWS 서비스:**
  - Amazon API Gateway (WebSocket API)
  - AWS Lambda (이벤트 트리거)
- **주요 기능:**
  - 실시간 알림 기능 제공
  - WebSocket 기반 양방향 통신 지원
  - 프론트엔드와의 즉시 알림 연동 가능

### 4️⃣ **network-infrastructure**

- **목적:** 네트워크 인프라(VPC, 서브넷, 보안 그룹 등) 정의
- **사용 AWS 서비스:**
  - Amazon VPC (프라이빗 및 퍼블릭 네트워크 구성)
  - 보안 그룹 (EC2 및 기타 서비스 방화벽 규칙)
  - 라우트 테이블 및 NAT 게이트웨이 (네트워크 트래픽 관리)
- **주요 기능:**
  - 환경별 네트워크 설정 지원
  - AWS 서비스 간 안전한 트래픽 제어
  - 동적 서브넷 맵핑 및 자동 프로비저닝

### 5️⃣ **video-streaming-ec2**

- **목적:** EC2 인스턴스를 활용한 Kinesis Video Stream 송출 시뮬레이션
- **사용 AWS 서비스:**
  - Amazon EC2 (비디오 송출 서버)
  - IAM 역할 (비디오 스트리밍 권한 설정)
- **주요 기능:**
  - 로컬 및 클라우드 환경에서 비디오 스트리밍 테스트 지원
  - 스트리밍 애플리케이션 개발 및 테스트 환경 제공
  - Kinesis Video Stream과 연동하여 실시간 영상 송출

## 🔧 모듈 사용 방법

각 모듈은 루트 Terraform 구성에서 호출됩니다. 예제는 다음과 같습니다:

```hcl
module "frontend-hosting" {
  source       = "./modules/frontend-hosting"
  project_name = var.project_name
}
```

### **Terraform 설정 적용**

인프라를 배포하려면 다음 명령어를 실행합니다:

```sh
terraform init
terraform apply -auto-approve
```

### **다양한 환경을 위한 Terraform 워크스페이스 사용**

이 프로젝트는 Terraform 워크스페이스를 사용하여 `dev`, `staging`, `prod` 등의 환경을 관리합니다.

```sh
terraform workspace new dev
terraform workspace select dev
```

## 📌 결론

이 Terraform 모듈은 유지보수성과 확장성을 고려하여 설계되었습니다. 각 모듈은 특정 기능을 수행하며, 이를 조합하여 AWS 인프라를 손쉽게 관리할 수 있습니다. 보다 자세한 내용은 각 모듈의 `README.md`를 참조하세요.

---

🔹 **마지막 업데이트:** 2025-02-02
