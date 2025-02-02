# output definitions

output "apigw_url" {
  description = "URL for API Gateway"
  value = aws_apigatewayv2_api.apigw_http.api_endpoint
}
