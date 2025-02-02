# ==============================
# 🗄 Lambda 코드 압축 (archive_file 사용)
# ==============================
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${path.root}/../backend/lambdas/event-messaging"
  output_path = "${path.module}/src/event_messaging_lambda.zip"
}

# ==============================
# 📦 DynamoDB 테이블 (WebSocket 연결 관리)
# ==============================
resource "aws_dynamodb_table" "websocket_connections" {
  name           = "${var.project_name}-${var.environment}-websocket-connections"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }
}

# ==============================
# 🖥️ AWS Lambda 함수 생성 (WebSocket & Kinesis 이벤트 처리)
# ==============================
resource "aws_lambda_function" "event_messaging_lambda" {
  function_name = "${var.project_name}-${var.environment}-event-messaging-lambda"
  runtime       = "python3.10"
  handler       = "main.lambda_handler"
  timeout       = 300

  role          = aws_iam_role.lambda_role.arn
  filename      = data.archive_file.lambda_package.output_path

  environment {
    variables = {
      WEBSOCKET_ENDPOINT = "https://${aws_apigatewayv2_api.websocket_api.id}.execute-api.${var.region}.amazonaws.com/${aws_apigatewayv2_stage.websocket_stage.name}"
      DYNAMODB_TABLE     = aws_dynamodb_table.websocket_connections.name
    }
  }

  source_code_hash = data.archive_file.lambda_package.output_base64sha256
}

# ==============================
# 🌐 WebSocket API Gateway 생성 (IAM 인증 적용)
# ==============================
resource "aws_apigatewayv2_api" "websocket_api" {
  name          = "${var.project_name}-${var.environment}-websocket-api"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "websocket_stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "prod"
  auto_deploy = true
}

# ==============================
# 🔗 API Gateway와 Lambda 연결 (INTEGRATION 추가)
# ==============================
resource "aws_apigatewayv2_integration" "websocket_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.event_messaging_lambda.invoke_arn
  integration_method = "POST"
}

# ==============================
# 🔗 WebSocket API Gateway 라우팅 설정 (IAM 인증: $connect ONLY)
# ==============================
resource "aws_apigatewayv2_route" "websocket_route_connect" {
  api_id            = aws_apigatewayv2_api.websocket_api.id
  route_key         = "$connect"
  target            = "integrations/${aws_apigatewayv2_integration.websocket_integration.id}"
  # authorization_type = "AWS_IAM"
}

# 📌 클라이언트가 연결을 해제할 때 실행되는 $disconnect 라우트
resource "aws_apigatewayv2_route" "websocket_route_disconnect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_integration.id}"
}

# 📌 클라이언트가 특정 메시지를 보낼 때 실행되는 sendMessage 라우트
resource "aws_apigatewayv2_route" "websocket_route_message" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_integration.id}"
}

# 📌 정의되지 않은 모든 액션을 처리하는 기본 $default 라우트
resource "aws_apigatewayv2_route" "websocket_route_default" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.websocket_integration.id}"
}


# ==============================
# 🔑 API Gateway가 Lambda를 호출할 수 있도록 Lambda Permission 추가
# ==============================
resource "aws_lambda_permission" "apigw_websocket_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_messaging_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
}


# ==============================
# 🔗 Lambda에 Kinesis Data Stream 트리거 추가
# ==============================
resource "aws_lambda_event_source_mapping" "event_messaging_kinesis_trigger" {
  event_source_arn  = var.kinesis_stream_arn
  function_name     = aws_lambda_function.event_messaging_lambda.arn
  starting_position = "LATEST"
  batch_size        = 10
}

# ==============================
# 🔐 IAM 역할 및 정책 (Lambda 실행 권한)
# ==============================
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_kinesis_websocket_policy" {
  name = "${var.project_name}-${var.environment}-lambda-kinesis-websocket-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ]
        Resource = var.kinesis_stream_arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "execute-api:ManageConnections"
        ]
        Resource = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.websocket_connections.arn
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_kinesis_websocket_attachment" {
  name       = "${var.project_name}-${var.environment}-lambda-kinesis-websocket-attachment"
  policy_arn = aws_iam_policy.lambda_kinesis_websocket_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
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
    REACT_APP_WEBSOCKET_API_URL = aws_apigatewayv2_stage.websocket_stage.invoke_url
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
