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

variable "vpc_id" {
  description = "EC2를 배포할 VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "EC2를 배포할 서브넷 ID"
  type        = string
}

variable "kinesis_stream_name" {
  description = "Kinesis Video Stream 이름"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "ssh_cidr_blocks" {
  description = "SSH 접근을 허용할 CIDR 목록"
  type        = list(string)
}
