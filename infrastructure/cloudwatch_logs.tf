#-------------------------------------------------------------------
# CloudWatch Log Groups for Lambda Functions
#-------------------------------------------------------------------

# Lambda - getDataAdmin
resource "aws_cloudwatch_log_group" "lambda_logs_get_data_admin" {
  name              = "/aws/lambda/${local.lambda_get_data_admin_name}"
  retention_in_days = local.log_retention

  # Terraform to delete the CloudWatch Log Group and all its logs when we run terraform destroy
  skip_destroy      = false
}

# Lambda - getDataUser
resource "aws_cloudwatch_log_group" "lambda_logs_get_data_user" {
  name              = "/aws/lambda/${local.lambda_get_data_user_name}"
  retention_in_days = local.log_retention

  # Terraform to delete the CloudWatch Log Group and all its logs when we run terraform destroy
  skip_destroy      = false
}

# Lambda - putDataUser
resource "aws_cloudwatch_log_group" "lambda_logs_put_data_user" {
  name              = "/aws/lambda/${local.lambda_put_data_user_name}"
  retention_in_days = local.log_retention

  # Terraform to delete the CloudWatch Log Group and all its logs when we run terraform destroy
  skip_destroy      = false
}
