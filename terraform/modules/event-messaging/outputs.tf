# ==============================
# 📤 출력 변수
# ==============================
output "lambda_function_name" {
  value = aws_lambda_function.event_messaging_lambda.function_name
}

output "websocket_api_url" {
  value = aws_apigatewayv2_stage.websocket_stage.invoke_url
}

output "websocket_api_arn" {
  value = aws_apigatewayv2_api.websocket_api.execution_arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.websocket_connections.name
}
