# output definitions

output "apigw_url" {
  description = "URL for API Gateway"
  value = module.apigw_park.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Client ID associated with the Cognito User Pool"
  value = aws_cognito_user_pool_client.main.id
}
