# ========================================
# 🌍 프로젝트 및 환경 설정
# ========================================
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

# ========================================
# 🗄️ Backend Configuration (Terraform State 관리)
# ========================================
variable "backend_bucket_name" {
  description = "Terraform 상태 파일을 저장할 S3 버킷 이름"
  type        = string
}

variable "backend_dynamodb_table" {
  description = "Terraform 상태 잠금(DynamoDB) 테이블 이름"
  type        = string
}

# ========================================
# 🌐 네트워크 설정 (VPC & 서브넷)
# ========================================
variable "network_config" {
  description = "VPC 및 네트워크 설정"
  type = object({
    vpc_cidr            = string
    availability_zones  = list(string)
    public_subnet_cidrs = list(string)
    private_subnet_cidrs = list(string)
    enable_nat_gateway  = bool
  })
}

# ========================================
# 🖥️ EC2 배포 설정
# ========================================
variable "sample_streaming" {
  description = "샘플 스트리밍 EC2 배포 여부"
  type        = bool
}

# 🔐 보안 그룹 설정 (Security Group)
# ----------------------------------------
variable "ssh_allowed_cidrs" {
  description = "EC2 인스턴스 보안 그룹에서 허용할 CIDR 목록 (예: SSH, 내부 통신 등)"
  type        = list(string)
}

# ========================================
# 📹 Kinesis Video Stream 설정
# ========================================
variable "kvs_retention_hours" {
  description = "Kinesis Video Stream 데이터 보존 시간 (시간 단위)"
  type        = number
}

# ========================================
# 🧠 Rekognition 설정 (얼굴 인식)
# ========================================
variable "enable_rekognition" {
  description = "Rekognition 활성화 여부"
  type        = bool
}

variable "face_match_threshold" {
  description = "Rekognition 얼굴 매칭 임계값 (0~100)"
  type        = number
}

# ==============================
# 📩 AWS SNS 설정 (웹 푸시 알림)
# ==============================
variable "sns_topic_name" {
  description = "SNS Topic 이름"
  type        = string
}

# ========================================
# 🌍 CloudFront 설정
# ========================================
variable "price_class" {
  description = "CloudFront 가격 클래스"
  type        = string
  default     = "PriceClass_200"
}

# 🔐 WAF IP 기반 접근제어 설정 (CloudFront)
# ----------------------------------------
variable "enable_waf" {
  description = "WAF를 활용한 IP 기반 접근제어 활성화 여부"
  type        = bool
  default     = true
}

variable "waf_allowed_cidrs" {
  description = "CloudFront WAF에서 허용할 IP 주소 목록 (CIDR 형식)"
  type        = list(string)
  default     = []
}

# 🌍 Geo 기반 접근제어 설정 (CloudFront)
# ----------------------------------------
variable "enable_geo_restriction" {
  description = "CloudFront에서 지역별 접근제어 활성화 여부"
  type        = bool
  default     = false
}

variable "geo_restriction_type" {
  description = "Geo 제한 방식 ('whitelist' 또는 'blacklist')"
  type        = string
  default     = "whitelist"
}

variable "geo_restriction_locations" {
  description = "허용 또는 차단할 국가 목록 (ISO 3166-1 Alpha-2 코드 사용)"
  type        = list(string)
  default     = ["KR"]
}
