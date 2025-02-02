# Terraform AWS 네트워크 인프라 모듈

이 모듈은 AWS에서 네트워크 인프라를 구성하기 위한 Terraform 코드입니다.  
VPC, 서브넷, 인터넷 게이트웨이, NAT 게이트웨이 등의 주요 네트워크 리소스를 자동으로 생성하고 관리합니다.

## 📌 주요 구성 요소

- **VPC**: CIDR 블록을 기반으로 생성됩니다.
- **서브넷**: Public 및 Private 서브넷을 자동으로 생성하며, AZ(Availability Zone)를 자동 선택합니다.
- **인터넷 게이트웨이 (IGW)**: 퍼블릭 서브넷을 위한 인터넷 연결을 제공합니다.
- **NAT 게이트웨이 (선택적 활성화 가능)**: 프라이빗 서브넷에서 인터넷으로 나가는 트래픽을 지원합니다.

## 📂 파일 구조

```bash
📂 terraform-network
 ├── main.tf          # VPC, 서브넷, 인터넷 게이트웨이 정의
 ├── nat.tf           # NAT 게이트웨이 설정 (선택 사항)
 ├── outputs.tf       # Terraform 출력 값 정의
 ├── variables.tf     # 변수 정의
```

## 🔧 주요 변수

| 변수명                                | 설명                                       |
| ------------------------------------- | ------------------------------------------ |
| `project_name`                        | 프로젝트 이름 (예: `my-project`)           |
| `environment`                         | 배포 환경 (`dev`, `staging`, `prod` 등)    |
| `network_config.vpc_cidr`             | VPC의 CIDR 블록 (예: `10.0.0.0/16`)        |
| `network_config.availability_zones`   | 가용 영역 리스트                           |
| `network_config.public_subnet_cidrs`  | 퍼블릭 서브넷 CIDR 블록 리스트             |
| `network_config.private_subnet_cidrs` | 프라이빗 서브넷 CIDR 블록 리스트           |
| `network_config.enable_nat_gateway`   | NAT 게이트웨이 사용 여부 (기본값: `false`) |

## 📤 Terraform Outputs

| 출력 값               | 설명                              |
| --------------------- | --------------------------------- |
| `vpc_id`              | 생성된 VPC ID                     |
| `public_subnet_ids`   | Public 서브넷 ID 목록             |
| `private_subnet_ids`  | Private 서브넷 ID 목록            |
| `internet_gateway_id` | 인터넷 게이트웨이 ID              |
| `nat_gateway_id`      | NAT 게이트웨이 ID (활성화된 경우) |
