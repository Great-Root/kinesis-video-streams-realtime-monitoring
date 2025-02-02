variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "Terraform workspace에서 설정되는 환경"
  type        = string
}

variable "network_config" {
  description = "네트워크 설정 (VPC, 서브넷, NAT 포함)"
  type = object({
    vpc_cidr            = string
    availability_zones  = list(string)
    public_subnet_cidrs = list(string)
    private_subnet_cidrs = list(string)
    enable_nat_gateway  = bool
  })
}
