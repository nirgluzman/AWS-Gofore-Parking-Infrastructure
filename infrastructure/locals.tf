locals {
  app_name          = "park-manager"

  apigw_name        = "${local.app_name}-api"
  apigw_stage_name  = "dev"

  lambda_get_data_admin_name = "${local.app_name}-getDataAdmin"

  ddb_table_name    = "${local.app_name}-cars-data"
}
