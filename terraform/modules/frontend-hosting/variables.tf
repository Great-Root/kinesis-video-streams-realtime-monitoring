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
# 📂 CloudFront 설정
# ==============================
variable "price_class" {
  description = "CloudFront 가격 클래스"
  type        = string
  default     = "PriceClass_100"
}

# ==============================
# 🔐 WAF IP 기반 접근제어 설정
# ==============================
variable "enable_waf" {
  description = "WAF를 활용한 IP 기반 접근제어 활성화 여부"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "허용할 IP 주소 목록 (CIDR 형식)"
  type        = list(string)
  default     = []
}

# ==============================
# 🌍 Geo 기반 접근제어 설정 (whitelist & blacklist 지원)
# ==============================
variable "enable_geo_restriction" {
  description = "지역별 접근제어 활성화 여부"
  type        = bool
  default     = false
}

variable "geo_restriction_type" {
  description = "Geo 제한 방식 (whitelist 또는 blacklist)"
  type        = string
  default     = "whitelist"
}

variable "geo_restriction_locations" {
  description = "허용 또는 차단할 국가 목록 (ISO 3166-1 Alpha-2 코드)"
  type        = list(string)
  default     = ["KR"]
}

# # ==============================
# # 🔐 Cognito 인증 설정
# # ==============================
# variable "cognito_identity_pool_id" {
#   description = "Cognito Identity Pool ID"
#   type        = string
# }

# variable "cognito_user_pools_id" {
#   description = "Cognito User Pool ID"
#   type        = string
# }

# variable "cognito_user_pools_web_client_id" {
#   description = "Cognito User Pool Web Client ID"
#   type        = string
# }

variable "websocket_api_arn" {
  description = "WebSocket API Gateway ARN"
  type        = string
}
