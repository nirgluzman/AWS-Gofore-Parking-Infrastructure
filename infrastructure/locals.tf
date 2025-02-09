locals {
  app_name          = "park-manager"

  user_pool_name          = "${local.app_name}-admin-users"   # Cognito user pool name
  user_pool_client_name   = "${local.app_name}-admin-client"  # Cognito user pool client name (friendly identifier)
  user_pool_domain_prefix = "${local.app_name}"               # Cognito domain prefix (Cognito's hosted UI)
  user_pool_client_callback_urls =  [                         # Cognito user pool client callback URLs
      "http://localhost:3000/callback"    # local development
  ]

  apigw_name        = "${local.app_name}-api"
  apigw_stage_name  = "dev"

  lambda_get_data_admin_name = "${local.app_name}-getDataAdmin"
  lambda_get_data_user_name  = "${local.app_name}-getDataUser"
  lambda_put_data_user_name  = "${local.app_name}-putDataUser"

  ddb_table_name    = "${local.app_name}-cars-data"

  log_retention     = 7 # log retention in days
}
