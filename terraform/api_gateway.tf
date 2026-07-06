resource "aws_apigatewayv2_api" "transactions" {
  name          = "transaction-processing-api"
  protocol_type = "HTTP"

  tags = {
    Name      = "transaction-processing-api"
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.transactions.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.transaction_processor.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "transactions" {
  api_id = aws_apigatewayv2_api.transactions.id

  route_key = "POST /transactions"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.transactions.id

  name        = "$default"
  auto_deploy = true

  tags = {
    Name      = "transaction-processing-default-stage"
    ManagedBy = "Terraform"
    Project   = "AWS Automated Transaction Processing"
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_processor.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.transactions.execution_arn}/*/*"
}

output "transaction_api_endpoint" {
  description = "Base URL of the transaction processing API"
  value       = aws_apigatewayv2_api.transactions.api_endpoint
}
