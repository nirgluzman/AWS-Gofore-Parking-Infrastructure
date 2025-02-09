# main Terraform configuration

#-------------------------------------------------------------------
# DynamoDB Table
#-------------------------------------------------------------------

# Terraform module to create AWS DynamoDB resources
# https://registry.terraform.io/modules/terraform-aws-modules/dynamodb-table/aws/latest
module "ddb_park" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  name     = local.ddb_table_name # name of the DynamoDB table
  hash_key = "parkingSpot" # table partition key (primary key attribute)

  attributes = [
    {
      name = "parkingSpot"
      type = "N"
    }
  ]

  billing_mode = "PAY_PER_REQUEST" # on-demand billing
  deletion_protection_enabled = false # deletion protection is disabled
}

#-------------------------------------------------------------------
# Lambda Functions
#-------------------------------------------------------------------

# Terraform module to create AWS Lambda resource
# https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest
module "lambda_get_data_admin" {
  source   = "terraform-aws-modules/lambda/aws"

  description   = "Lambda function to get data from the database for admin users"

  function_name = local.lambda_get_data_admin_name
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  local_existing_package = "${path.module}/placeholder.zip" # the absolute path to an existing zip-file to use
  create_package         = false

  publish       = true # whether to publish creation/change as new Lambda Function Version

  # IAM Role configuration
  create_role   = false # tell the module to create a role
  lambda_role   = aws_iam_role.lambda_exec.arn # IAM role ARN attached to the Lambda Function.

  # define the permissions to allow API Gateway to invoke the Lambda function (see aws_lambda_permission)
  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.apigw_park.api_execution_arn}/*/*" # ARN of the API Gateway execution API (including stage and method)
    }
  }

  # CloudWatch Logs configuration
  use_existing_cloudwatch_log_group = true
  logging_log_group = aws_cloudwatch_log_group.lambda_logs_get_data_admin.name

  memory_size   = 512 # amount of memory in MB the Lambda function can use at runtime
  timeout       = 10  # amount of time the Lambda function has to run in seconds

  # environment variables which are accessible from the function code during execution
  environment_variables = {
    REGION     = "${var.aws_region}"
    TABLE_NAME = "${local.ddb_table_name}"
  }

  depends_on = [ aws_cloudwatch_log_group.lambda_logs_get_data_admin ]
}

module "lambda_get_data_user" {
  source   = "terraform-aws-modules/lambda/aws"

  description   = "Lambda function to get data from the database for normal users"

  function_name = local.lambda_get_data_user_name
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  local_existing_package = "${path.module}/placeholder.zip" # the absolute path to an existing zip-file to use
  create_package         = false

  publish       = true # whether to publish creation/change as new Lambda Function Version

  # IAM Role configuration
  create_role   = false # tell the module to create a role
  lambda_role   = aws_iam_role.lambda_exec.arn # IAM role ARN attached to the Lambda Function.

  # define the permissions to allow API Gateway to invoke the Lambda function (see aws_lambda_permission)
  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.apigw_park.api_execution_arn}/*/*" # ARN of the API Gateway execution API (including stage and method)
    }
  }

  # CloudWatch Logs configuration
  use_existing_cloudwatch_log_group = true
  logging_log_group = aws_cloudwatch_log_group.lambda_logs_get_data_user.name

  memory_size   = 512 # amount of memory in MB the Lambda function can use at runtime
  timeout       = 10  # amount of time the Lambda function has to run in seconds

  # environment variables which are accessible from the function code during execution
  environment_variables = {
    REGION     = "${var.aws_region}"
    TABLE_NAME = "${local.ddb_table_name}"
  }

  depends_on = [ aws_cloudwatch_log_group.lambda_logs_get_data_user ]
}

module "lambda_put_data_user" {
  source   = "terraform-aws-modules/lambda/aws"

  description   = "Lambda function to replace data in database for normal users"

  function_name = local.lambda_put_data_user_name
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  local_existing_package = "${path.module}/placeholder.zip" # the absolute path to an existing zip-file to use
  create_package         = false

  publish       = true # whether to publish creation/change as new Lambda Function Version

  # IAM Role configuration
  create_role   = false # tell the module to create a role
  lambda_role   = aws_iam_role.lambda_exec.arn # IAM role ARN attached to the Lambda Function.

  # define the permissions to allow API Gateway to invoke the Lambda function (see aws_lambda_permission)
  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.apigw_park.api_execution_arn}/*/*" # ARN of the API Gateway execution API (including stage and method)
    }
  }

  # CloudWatch Logs configuration
  use_existing_cloudwatch_log_group = true
  logging_log_group = aws_cloudwatch_log_group.lambda_logs_put_data_user.name

  memory_size   = 512 # amount of memory in MB the Lambda function can use at runtime
  timeout       = 10  # amount of time the Lambda function has to run in seconds

  # environment variables which are accessible from the function code during execution
  environment_variables = {
    REGION     = "${var.aws_region}"
    TABLE_NAME = "${local.ddb_table_name}"
  }

  depends_on = [ aws_cloudwatch_log_group.lambda_logs_put_data_user ]
}

#-------------------------------------------------------------------
# HTTP API Gateway with JWT authorizer
#-------------------------------------------------------------------

# Terraform module to create AWS API Gateway v2 (HTTP/WebSocket)
# https://registry.terraform.io/modules/terraform-aws-modules/apigateway-v2/aws/latest
module "apigw_park" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name        = local.apigw_name
  description = "HTTP API Gateway for Park Manager"

  protocol_type = "HTTP"     # HTTP API

  create_domain_name = false # whether to create API domain name resource

  # CORS configuration which applies to all resources (endpoints) within the HTTP API
  cors_configuration = {
    allow_headers     = ["Content-Type", "Authorization"] # allowed request headers
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"] # allowed HTTP methods
    allow_origins     = ["*"] # allowed origin domains
    max_age           = 3600 # optional: Maximum age (in seconds) the results of a preflight request can be cached
  }

  stage_name   = local.apigw_stage_name # deployment stage name
  create_stage = true
  deploy_stage = true

  # Access logs configuration to record information about requests made to the API
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = local.log_retention
    format = jsonencode({
      # information about the API Gateway execution context
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus"
        }
      }
    })
  }

  # Map of API gateway authorizers to create
    authorizers = {
    jwt_authorizer = {
      # IMPORTANT: This JWT authorizer verifies the JWT's signature, audience, issuer, and expiration.
      # It DOES NOT detect JWTs revoked by Cognito if their expiration time has not been reached.
      name             = "jwt_auth"
      authorizer_type  = "JWT"
      identity_sources = ["$request.header.Authorization"] # tells API Gateway it's a Bearer token in the "Authorization" header

      # configure the JWT verification process
      jwt_configuration = {
        audience = [aws_cognito_user_pool_client.main.id] # intended recipient of the token (ensures that the JWT was specifically issued for your application and not for some other application)
        issuer   = "https://${aws_cognito_user_pool.main.endpoint}" # the entity that issued the token
      }
    }
  }

  # Routes & Integrations
  create_routes_and_integrations = true
  routes = {
    # combination of HTTP method and path that clients use to access the API endpoint

    "GET /admin" = {
      description         = "Get data from the database for admin users"
      authorization_type  = "JWT"
      authorizer_key      = "jwt_authorizer"
      integration = {
        # API Gateway uses the integration to invoke the backend API
        uri    = module.lambda_get_data_admin.lambda_function_arn
        type   = "AWS_PROXY"
        method = "POST"
        # for AWS_PROXY integrations, integration_method must be POST.
        # API Gateway uses POST to forward the entire request to the backend.
      }
    }

    "GET /user/{type}" = {
      description         = "Get data from the database for normal users"
      authorization_type  = "NONE"
      integration = {
        uri    = module.lambda_get_data_user.lambda_function_arn
        type   = "AWS_PROXY"
        method = "POST"
      }
    }

    "PUT /user/{type}" = {
      description = "Replace data in the database for normal users"
      authorization_type  = "NONE"
      integration = {
        uri    = module.lambda_put_data_user.lambda_function_arn
        type   = "AWS_PROXY"
        method = "POST"
      }
    }
  }
}
