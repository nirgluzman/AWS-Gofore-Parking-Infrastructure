#-------------------------------------------------------------------
# IAM Role assumed by the Lambda Functions during execution
#-------------------------------------------------------------------

resource "aws_iam_role" "lambda_exec" {
  name = "${local.app_name}-lambda-exec-role"
  description = "IAM role for Lambda function execution"

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

resource "aws_iam_policy" "lambda_exec" {
  name = "${local.app_name}-lambda-exec-ddb-logs-policy"
  description = "Policy granting Lambda function permissions for DynamoDB and CloudWatch Logs"

  policy = jsonencode({
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeTable",
                "dynamodb:Get",
                "dynamodb:Scan",
                "dynamodb:PutItem",
                "dynamodb:Update",
                "dynamodb:Delete"
            ],
            "Resource": "${module.ddb_park.dynamodb_table_arn}"
        }
    ]
  })
}

# attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec.arn
}
