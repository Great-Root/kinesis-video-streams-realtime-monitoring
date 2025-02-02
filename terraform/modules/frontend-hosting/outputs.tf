output "s3_bucket_name" {
  description = "정적 웹사이트를 호스팅하는 S3 버킷 이름"
  value       = aws_s3_bucket.frontend.bucket
}

output "cloudfront_domain_name" {
  description = "CloudFront 배포 도메인 (CDN)"
  value       = aws_cloudfront_distribution.frontend_cdn.domain_name
}

output "waf_web_acl_id" {
  description = "WAF WebACL ID (WAF 활성화 시)"
  value       = var.enable_waf ? aws_wafv2_web_acl.frontend_waf[0].id : null
}

output "geo_restriction_status" {
  description = "Geo 기반 접근제어 설정 상태"
  value       = var.enable_geo_restriction ? "${var.geo_restriction_type} - ${join(", ", var.geo_restriction_locations)}" : "None"
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.user_pool.id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Web Client ID"
  value       = aws_cognito_user_pool_client.user_pool_client.id
}

output "identity_pool_id" {
  description = "Cognito Identity Pool ID"
  value       = aws_cognito_identity_pool.identity_pool.id
}

output "authenticated_role_arn" {
  description = "IAM Role for Authenticated Cognito Users"
  value       = aws_iam_role.authenticated_role.arn
}
