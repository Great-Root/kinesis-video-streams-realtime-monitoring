# video-processing 모듈

## 📌 소개

`video-processing` 모듈은 **Kinesis Video Stream 및 Rekognition을 관리하며, 선택적으로 EC2를 배포하여 사용자가 사용할 수 있도록 하는** 모듈입니다.
실시간 비디오 배열이나 유용한 프로세스를 분석할 수 있도록 강화되었습니다.

## 📂 모듈 파일 구조

```
📂 modules/video-processing
 ┣ 📜 main.tf           # Kinesis Video Stream, Rekognition, EC2 설정
 ┣ 📜 variables.tf      # 모듈에서 사용되는 변수 정의
 ┣ 📜 outputs.tf        # 생성된 리소스 출력
 ┗ 📜 README.md         # 모듈 설명 문서
```

## 🛠 사용된 AWS 리소스

- **Amazon Kinesis Video Stream** - 실시간 비디오 수집
- **Amazon Rekognition** - 유형 인식, 행동 분석
- **Amazon EC2 (optional)** - 사용자가 복합 플레이어를 사용할 경우 배포

## 🔧 모듈 변수

| 변수명                | 설명                                  | 예제 값              |
| --------------------- | ------------------------------------- | -------------------- |
| `project_name`        | 프로젝트 이름                         | `"my-video-project"` |
| `environment`         | 실행 환경 (`dev`, `prod` 등)          | `"dev"`              |
| `region`              | AWS 리전                              | `"us-west-2"`        |
| `vpc_id`              | VPC ID                                | `"vpc-12345678"`     |
| `subnet_id`           | EC2를 배포할 서브넷                   | `"subnet-12345678"`  |
| `kvs_retention_hours` | Kinesis Video Stream 데이터 보존 시간 | `24`                 |
| `enable_rekognition`  | Rekognition 활성화 여부               | `true` or `false`    |
| `sample_streaming`    | 사용자 비디오 스트림 필요 여부        | `true` or `false`    |
| `ssh_cidr_blocks`     | SSH 접근을 허용할 CIDR 목록           | `["203.0.113.0/24"]` |

## 🚀 Terraform 코드 예제

```hcl
module "video_processing" {
  source              = "./modules/video-processing"
  project_name        = var.project_name
  environment         = terraform.workspace
  region              = var.region
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.public_subnet_ids["public1"]
  kvs_retention_hours = 24
  enable_rekognition  = true
  sample_streaming    = true  # EC2 배포 여부
  ssh_cidr_blocks     = ["0.0.0.0/0"]
}
```

## 🏗 Terraform 적용 방법

### **1️⃣ Terraform 배포**

```sh
terraform init
terraform apply -auto-approve
```

### **2️⃣ Kinesis Video Stream 확인**

AWS 콘솔에서 **Kinesis Video Streams** 서비스로 이동하여 생성된 스트림을 확인할 수 있습니다.

### **3️⃣ Rekognition Collection 확인**

```sh
aws rekognition list-collections --region <AWS_REGION>
```

## 📌 참고 사항

- `enable_rekognition` 변수를 `true`로 설정하면 **Rekognition Collection이 생성**됩니다.
- `sample_streaming` 변수를 `true`로 설정하면 **EC2 인스턴스가 배포**됩니다.

---

✅ **AWS에서 실시간 비디오 스트리밍과 AI 분석을 자동으로 설정할 수 있도록 경영해 보세요!** 🚀
