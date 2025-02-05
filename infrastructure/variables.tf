# input variable definitions

variable "aws_region" {
  description = "AWS region for all resources"
  type    = string
  default = "us-east-1"
}

variable "user_pool_name" {
  description = "Cognito user pool name"
  type        = string
  default     = "park-manager-admin-users"
}

variable "user_pool_client_name" {
  description = "Cognito user pool client name (friendly identifier)"
  type        = string
  default     = "park-manager-admin-client"
}

variable "user_pool_client_callback_urls" {
  description = "Cognito user pool client callback URLs"
  type        = list(string)
  default     = [
      "http://localhost:3000/callback"    # local development
  ]
}

variable "user_pool_domain_prefix" {
  description = "Cognito domain prefix (Cognito's hosted UI)"
  type        = string
  default     = "park-manager"
}

variable "log_retention" {
  description = "log retention in days"
  type = number
  default = 7
}
