# ==============================
# 🌍 프로젝트 및 환경 설정
# ==============================
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "environment" {
  description = "Terraform workspace에서 설정되는 환경"
  type        = string
}

# ==============================
# 🖥️ EC2 배포 설정
# ==============================
variable "sample_streaming" {
  description = "샘플 스트리밍 EC2 배포 여부"
  type        = bool
}

variable "vpc_id" {
  description = "EC2 인스턴스를 배포할 VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "EC2 인스턴스를 배포할 서브넷 ID"
  type        = string
}

variable "ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 CIDR 목록"
  type        = list(string)
}

# ==============================
# 📹 Kinesis Video Stream 설정
# ==============================
variable "kvs_retention_hours" {
  description = "Kinesis Video Stream 데이터 보존 시간 (시간 단위)"
  type        = number
}

# ==============================
# 🧠 Rekognition 설정
# ==============================
variable "enable_rekognition" {
  description = "Rekognition 활성화 여부"
  type        = bool
}

variable "face_match_threshold" {
  description = "Rekognition 얼굴 매칭 임계값 (0~100)"
  type        = number
}
