# input variable definitions

variable "aws_region" {
  description = "AWS region for all resources"

  type    = string
  default = "us-east-1"
}

variable "log_retention" {
  description = "log retention in days"
  type = number
  default = 7
}
