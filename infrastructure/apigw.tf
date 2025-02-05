# HTTP API Gateway with JWT authorizer

resource "aws_apigatewayv2_api" "apigw_http" {
  description = "HTTP API Gateway for Park Manager"

  name          = local.apigw_name
  protocol_type = "HTTP"    # HTTP API

  # CORS configuration which applies to all resources (endpoints) within the HTTP API
  cors_configuration {
    allow_headers     = ["Content-Type", "Authorization"] # allowed request headers
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"] # allowed HTTP methods
    allow_origins     = ["*"] # allowed origin domains
    max_age           = 3600 # optional: Maximum age (in seconds) the results of a preflight request can be cached
  }
}

resource "aws_apigatewayv2_stage" "apigw_stage" {
  api_id = aws_apigatewayv2_api.apigw_http.id
  name   = local.apigw_stage_name

  auto_deploy = true # automatically deploy the default stage

  # configure logging for API requests and responses
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

  depends_on = [aws_cloudwatch_log_group.apigw]
}

# define the connection between API Gateway HTTP API and the backend service
resource "aws_apigatewayv2_integration" "apigw_lambda_get_data_admin" {
  api_id = aws_apigatewayv2_api.apigw_http.id

  integration_uri    = aws_lambda_function.get_data_admin.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  # for AWS_PROXY integrations, integration_method must be POST.
  # API Gateway uses POST to forward the entire request to the backend.
}

# define the path and HTTP method that clients use to access the API
resource "aws_apigatewayv2_route" "admin_get" {
  api_id = aws_apigatewayv2_api.apigw_http.id

  # combination of HTTP method and path that clients use to access the API endpoint
  route_key = "GET /admin"

  # define what happens after a request matches the route key
  target    = "integrations/${aws_apigatewayv2_integration.apigw_lambda_get_data_admin.id}"

  # define authorization for the route
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt_auth.id
}

# allow API Gateway to invoke the Lambda functions
resource "aws_lambda_permission" "apigw-get_data_admin" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_data_admin.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.apigw_http.execution_arn}/*/*"
}

# define JWT authorizer for the HTTP API Gateway.
# IMPORTANT: This JWT authorizer verifies the JWT's signature, audience, issuer, and expiration.
# It DOES NOT detect JWTs revoked by Cognito if their expiration time has not been reached.
resource "aws_apigatewayv2_authorizer" "jwt_auth" {
  name             = "cognito_jwt_auth"
  api_id           = aws_apigatewayv2_api.apigw_http.id # associate the JWT authorizer with the HTTP API
  authorizer_type  = "JWT" # authorizer to verify JWTs
  identity_sources = ["$request.header.Authorization"]

  # configure the JWT verification process
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.main.id] # intended recipient of the token (ensures that the JWT was specifically issued for your application and not for some other application)
    issuer   = "https://${aws_cognito_user_pool.main.endpoint}" # the entity that issued the token
  }
}

# define a CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/api_gateway/${local.apigw_name}"
  retention_in_days = var.log_retention

  # Terraform to delete the CloudWatch Log Group and all its logs when we run terraform destroy
  skip_destroy      = false
}
