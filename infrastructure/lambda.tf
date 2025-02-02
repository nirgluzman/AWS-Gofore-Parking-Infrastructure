# Lambda functions

resource "aws_lambda_function" "get_data_admin" {
  description   = "Lambda function to get data from the database for admin users"
  function_name = local.lambda_get_data_admin_name

  runtime   = "nodejs22.x"
  handler   = "index.handler"

  publish   = false # whether to publish creation/change as new Lambda Function Version
  filename  = "${path.module}/placeholder.zip" # point to the temporary placeholder file

  # role that Lambda function will assume when it executes
  role = aws_iam_role.lambda_exec.arn

  memory_size = 512 # amount of memory in MB the Lambda function can use at runtime
  timeout     = 10  # amount of time the Lambda function has to run in seconds

  # environment variables which are accessible from the function code during execution
  environment {
    variables = {
      REGION = "${var.aws_region}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_logs_get_data_admin]
}

# role that Lambda function will assume when it executes
resource "aws_iam_role" "lambda_exec" {
  name = "${local.app_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_exec_policy" {
  name = "${local.app_name}-lambda-exec-ddb-logs-policy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}

# define a CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs_get_data_admin" {
  name              = "/aws/lambda/${local.lambda_get_data_admin_name}"
  retention_in_days = var.log_retention

  # Terraform to delete the CloudWatch Log Group and all its logs when we run terraform destroy
  skip_destroy      = false
}
