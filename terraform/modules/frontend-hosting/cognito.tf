# ==============================
# 🚀 AWS Cognito User Pool 생성
# ==============================
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.project_name}-${var.environment}-user-pool"

  username_attributes       = ["email"]
  auto_verified_attributes  = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }
}

# ==============================
# 🛠️ AWS Cognito User Pool Client 생성
# ==============================
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                         = "${var.project_name}-client"
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  generate_secret              = false
  explicit_auth_flows          = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  supported_identity_providers = ["COGNITO"]
  
  callback_urls = [
    "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/",
    "http://localhost:3000/"
  ]

  logout_urls = [
    "https://${aws_cloudfront_distribution.frontend_cdn.domain_name}/",
    "http://localhost:3000/"
  ]
}

# ==============================
# 🔐 AWS Cognito Identity Pool 생성
# ==============================
resource "aws_cognito_identity_pool" "identity_pool" {
  identity_pool_name               = "${var.project_name}-${var.environment}-identity-pool"
  allow_unauthenticated_identities = false
  
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.user_pool_client.id
    provider_name           = aws_cognito_user_pool.user_pool.endpoint
  }
}

# ==============================
# 🎭 IAM Role for Cognito Identity Pool (Authenticated Users)
# ==============================
resource "aws_iam_role" "authenticated_role" {
  name = "${var.project_name}-${var.environment}-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "cognito-identity.amazonaws.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "authenticated"
        }
      }
    }]
  })
}

# ==============================
# 📜 IAM Policy Attachment for Authenticated Users
# ==============================
resource "aws_iam_policy_attachment" "authenticated_policy" {
  name       = "${var.project_name}-${var.environment}-authenticated-policy"
  roles      = [aws_iam_role.authenticated_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "kinesisvideo_access" {
  name = "${var.project_name}-${var.environment}-kinesisvideo-access"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "kinesisvideo:DescribeStream",
          "kinesisvideo:GetDataEndpoint",
          "kinesisvideo:GetMedia",
          "kinesisvideo:PutMedia",
          "kinesisvideo:ListStreams",
          "kinesisvideo:GetHLSStreamingSessionURL"
        ],
        Resource = "arn:aws:kinesisvideo:${var.region}:${data.aws_caller_identity.current.account_id}:stream/*"
      }
    ]
  })
}

# ==============================
# 🔐 Cognito 인증된 사용자에게 API Gateway 접근 권한 부여
# ==============================
resource "aws_iam_role_policy" "api_gateway_access" {
  name = "${var.project_name}-${var.environment}-api-gateway-access"
  role = aws_iam_role.authenticated_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["execute-api:Invoke"]
        Resource = "${var.websocket_api_arn}/*"
      }
    ]
  })
}



# ==============================
# 🎭 IAM Role for Unauthenticated Cognito Users
# ==============================
resource "aws_iam_role" "unauthenticated_role" {
  name = "${var.project_name}-${var.environment}-unauthenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "cognito-identity.amazonaws.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.identity_pool.id
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "unauthenticated"
        }
      }
    }]
  })
}

# ==============================
# 📜 IAM Policy Attachment for Unauthenticated Users (읽기 전용 권한)
# ==============================
resource "aws_iam_policy_attachment" "unauthenticated_policy" {
  name       = "${var.project_name}-${var.environment}-unauthenticated-policy"
  roles      = [aws_iam_role.unauthenticated_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoReadOnly"
}

# ==============================
# 🔗 AWS Cognito Identity Pool Role Attachment
# ==============================
resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id

  roles = {
    "authenticated"   = aws_iam_role.authenticated_role.arn
    "unauthenticated" = aws_iam_role.unauthenticated_role.arn
  }
}

# .env 파일이 존재하는지 확인
data "external" "env_file_checker" {
  program = ["bash", "-c", <<EOT
if [ -f "${path.root}/../frontend/.env" ]; then
  echo '{ "exists": "true" }'
else
  echo '{ "exists": "false" }'
fi
EOT
  ]
}

# 기존 .env 파일의 내용을 읽음 (없으면 빈 값)
data "local_file" "existing_env" {
  count = data.external.env_file_checker.result.exists == "true" ? 1 : 0
  filename = "${path.root}/../frontend/.env"
}

# .env 파일에 추가할 변수 목록
locals {
  env_vars = {
    REACT_APP_AWS_PROJECT_REGION           = var.region
    REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID = aws_cognito_identity_pool.identity_pool.id
    REACT_APP_AWS_COGNITO_REGION           = var.region
    REACT_APP_AWS_USER_POOLS_ID            = aws_cognito_user_pool.user_pool.id
    REACT_APP_AWS_USER_POOLS_WEB_CLIENT_ID = aws_cognito_user_pool_client.user_pool_client.id
    GENERATE_SOURCEMAP                     = "false"
  }

  # 기존 파일 내용을 Map 형태로 변환
  existing_env_map = length(data.local_file.existing_env) > 0 ? {
    for line in split("\n", trimspace(data.local_file.existing_env[0].content)) :
      element(split("=", line), 0) => element(split("=", line), 1) if length(split("=", line)) > 1
  } : {}

  # 기존 값 + 새로운 값 병합
  merged_env_map = merge(local.existing_env_map, local.env_vars)

  # 최종 파일 내용 생성
  env_content = join("\n", [for k, v in local.merged_env_map : "${k}=${v}"])
}

# .env 파일을 업데이트
resource "local_file" "frontend_env" {
  filename = "${path.root}/../frontend/.env"
  content  = local.env_content
}
