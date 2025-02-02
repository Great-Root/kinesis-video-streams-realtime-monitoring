# 랜덤 4자리 suffix 생성
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# S3 버킷 자동 생성 (프로젝트명 + 환경 + 랜덤 4글자)
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}-${random_string.suffix.result}"
}

# S3 버킷 정책 (CloudFront만 접근 허용)
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# ==============================
# ⚙️ React 빌드 실행 (파일 변경 시 트리거)
# ==============================
resource "null_resource" "build_frontend" {
  provisioner "local-exec" {
    command = <<EOT
      cd ${path.root}/../frontend
      if [ -f package-lock.json ] && [ ! -d node_modules ]; then npm install; fi
      npm run build
    EOT
  }

  triggers = {
    env_hash         = filesha256("${path.root}/../frontend/.env")
    package_hash     = filesha256("${path.root}/../frontend/package.json")
    package_lock_hash = filesha256("${path.root}/../frontend/package-lock.json")
    src_hash         = md5(join("", [for f in fileset("${path.root}/../frontend/src", "**") : filesha256("${path.root}/../frontend/src/${f}")]))
    public_hash      = md5(join("", [for f in fileset("${path.root}/../frontend/public", "**") : filesha256("${path.root}/../frontend/public/${f}")]))
  }

  depends_on = [local_file.frontend_env]
}


# ==============================
# 📂 정적 웹사이트 파일 업로드 (S3)
# ==============================
resource "aws_s3_object" "frontend_files" {
  for_each = fileset("${path.root}/../frontend/build", "**")

  bucket = aws_s3_bucket.frontend.id
  key    = each.value
  source = "${path.root}/../frontend/build/${each.value}"

  content_type = lookup({
    "html"  = "text/html",
    "css"   = "text/css",
    "js"    = "application/javascript",
    "json"  = "application/json",
    "png"   = "image/png",
    "jpg"   = "image/jpeg",
    "jpeg"  = "image/jpeg",
    "svg"   = "image/svg+xml",
    "ico"   = "image/x-icon"
  }, regex("\\.([a-zA-Z0-9]+)$", each.value)[0], "binary/octet-stream")

  acl = "private"
  depends_on = [null_resource.build_frontend]
}


# WAF Web ACL 생성 (IP 기반 접근제어)
resource "aws_wafv2_web_acl" "frontend_waf" {
  count  = var.enable_waf ? 1 : 0
  name   = "${var.project_name}-waf"
  scope  = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf-metrics"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AllowSpecificIPs"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips[0].arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowSpecificIPs"
      sampled_requests_enabled   = true
    }
  }
}

# WAF 허용 IP 목록 (IP Set)
resource "aws_wafv2_ip_set" "allowed_ips" {
  count              = var.enable_waf ? 1 : 0
  name              = "${var.project_name}-allowed-ips"
  scope             = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses         = var.allowed_ip_ranges
}

# CloudFront Origin Access Identity (OAI) 생성
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.project_name} S3 bucket"
}

# CloudFront 배포 생성
resource "aws_cloudfront_distribution" "frontend_cdn" {
  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3Origin-${aws_s3_bucket.frontend.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"
  price_class         = var.price_class

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin-${aws_s3_bucket.frontend.id}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = var.enable_geo_restriction ? var.geo_restriction_type : "none"
      locations        = var.enable_geo_restriction ? var.geo_restriction_locations : []
    }
  }

  web_acl_id = var.enable_waf ? aws_wafv2_web_acl.frontend_waf[0].arn : null
}
