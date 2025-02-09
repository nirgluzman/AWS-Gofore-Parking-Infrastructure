#-------------------------------------------------------------------
# Cognito User Pool
#-------------------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name                     = local.user_pool_name
  auto_verified_attributes = ["email"] # the user attributes (email or phone_number) we want Cognito to auto send the confirmation code or link

  alias_attributes         = ["email"] # allows users to log in using attributes other than their username

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT" # Email delivery method to use
  }

  # Password must be at least 8 characters long, contains at least one number, one lowercase and one uppercase.
  password_policy {
    minimum_length    = 8     # minimum length of the password
    require_lowercase = true  # whether you've required users to use at least one lowercase letter in their password
    require_numbers   = true  # whether you've required users to use at least one number in their password
    require_symbols   = false
    require_uppercase = true
  }

  mfa_configuration = "OFF" # MFA Tokens are not required

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE" # Cognito to send a code; the app must confirm it with Cognito to activate the user signup
  }
  email_verification_message = "Your verification code is {####}."

  # attributes that are required when a new user is created (NOTE: username is implicitly required in Cognito)
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true

    string_attribute_constraints {
      min_length = 7
      max_length = 50
    }
  }
}

resource "aws_cognito_user_pool_client" "main" {
  user_pool_id          = aws_cognito_user_pool.main.id # user pool the client belongs to
  name                  = local.user_pool_client_name # name of the application client (friendly identifier)
  read_attributes       = ["email"] # defines the actual user profile fields that are readable
  write_attributes      = ["email"] # defines the user profile fields that are writable

  callback_urls         = local.user_pool_client_callback_urls # URLs in application that Cognito redirects users to after successful authentication
  allowed_oauth_flows   = ["implicit"] # access tokens are returned directly in the redirect URL - can be a security risk !!
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes  = ["openid", "profile"] # controls what data and operations the client application can access through OAuth flows
  generate_secret       = false # Client secret is not generated

  # the actions the client can handle in matters of authentication
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",     # allows the client to authenticate users with Secure Remote Password (SRP)
    "ALLOW_USER_PASSWORD_AUTH",# allows the client to authenticate users with their username and password
    "ALLOW_REFRESH_TOKEN_AUTH" # allows the client to refresh the access token
  ]

  # supported IdPs for Cognito's hosted UI
  supported_identity_providers = ["COGNITO"]
}

# configure a domain for Cognito's hosted UI, https://<domain>.auth.<AWS region code>.amazoncognito.com
resource "aws_cognito_user_pool_domain" "main" {
  domain = local.user_pool_domain_prefix # the domain prefix
  user_pool_id = aws_cognito_user_pool.main.id
}
