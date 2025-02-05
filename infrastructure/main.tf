# main Terraform configuration

# Terraform module to create AWS DynamoDB resources
# https://registry.terraform.io/modules/terraform-aws-modules/dynamodb-table/aws/latest
module "dynamodb_table" {
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
