# video-streaming-ec2 모듈 개요

## 📌 소개

`video-streaming-ec2` 모듈은 **AWS EC2 인스턴스를 배포하고, Kinesis Video Stream으로 비디오를 송출하는 역할**을 수행합니다. 이 모듈은 IP 카메라를 대체하여 AWS Kinesis Video Stream과 통합된 비디오 스트리밍 환경을 제공합니다.

## 🛠 사용된 AWS 리소스

- **Amazon EC2** - 비디오 스트리밍을 수행하는 인스턴스
- **IAM Role & Policy** - Kinesis Video Stream에 송출할 수 있는 권한 제공
- **Security Group** - SSH 및 비디오 스트리밍 포트 설정
- **User Data** - EC2 시작 시 GStreamer 및 WebRTC SDK를 실행하여 비디오 송출

## 📂 모듈 파일 구조

```
📂 modules/video-streaming-ec2
 ┣ 📜 main.tf           # EC2 인스턴스 및 관련 리소스 정의
 ┣ 📜 variables.tf      # 모듈에서 사용되는 변수 정의
 ┣ 📜 outputs.tf        # 모듈에서 생성된 리소스 출력
 ┣ 📜 user_data.sh      # EC2 초기 실행 스크립트 (비디오 스트리밍 설정)
 ┗ 📜 README.md         # 모듈 설명 문서
```

## 🔧 모듈 변수

| 변수명                | 설명                              | 예제 값                   |
| --------------------- | --------------------------------- | ------------------------- |
| `project_name`        | 프로젝트 이름                     | `"my-video-project"`      |
| `environment`         | 실행 환경 (`dev`, `prod` 등)      | `"dev"`                   |
| `vpc_id`              | VPC ID                            | `"vpc-12345678"`          |
| `subnet_id`           | EC2를 배포할 서브넷               | `"subnet-12345678"`       |
| `kinesis_stream_name` | Kinesis Video Stream 이름         | `"my-kinesis-stream"`     |
| `instance_type`       | EC2 인스턴스 타입                 | `"t3.medium"`             |
| `ami_id`              | AMI ID (Ubuntu 또는 Amazon Linux) | `"ami-0abcdef1234567890"` |

## 🚀 Terraform 코드 예제

```hcl
module "video-streaming-ec2" {
  source       = "./modules/video-streaming-ec2"
  project_name = "my-video-project"
  environment  = terraform.workspace
  vpc_id       = module.network-infrastructure.vpc_id
  subnet_id    = module.network-infrastructure.public_subnet_ids["public_a"]
  kinesis_stream_name = module.video-processing.kinesis_stream_name
}
```

## 🏗 Terraform 적용 방법

### **1️⃣ Terraform 배포**

```sh
terraform init
terraform apply -auto-approve
```

### **2️⃣ EC2 인스턴스 확인**

Terraform이 완료되면, AWS 콘솔에서 EC2 인스턴스가 생성된 것을 확인할 수 있습니다.

```sh
echo "EC2 Public IP: $(terraform output ec2_public_ip)"
```

### **3️⃣ SSH로 EC2 접속**

```sh
ssh -i my-key.pem ubuntu@<EC2-PUBLIC-IP>
```

## 🎥 Kinesis Video Stream 송출 방법

### **🔹 EC2에서 비디오 송출 실행**

#### 자동 실행 (User Data 적용)

```sh
sudo bash /opt/user_data.sh
```

### **🔹 WebRTC SDK 설치 및 실행**

```sh
cd ~/video-streams-producer/build
./kvs_gstreamer_sample my-kinesis-stream
```

## 📌 참고 사항

- `terraform workspace`를 활용하여 개발 (`dev`), 운영 (`prod`) 환경을 쉽게 전환할 수 있습니다.
- EC2의 비용 절감을 위해 사용 후 반드시 종료하거나 `terraform destroy`를 실행하세요.

---

✅ **이 모듈을 활용하면, AWS에서 EC2 기반 비디오 스트리밍 환경을 자동으로 구성할 수 있습니다!** 🚀
