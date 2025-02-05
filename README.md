# Interview Challenge - Park Manager

## GitHub repos

- https://github.com/nirgluzman/AWS-Gofore-Parking-Infrastructure.git (Cloud infrastructure)
- https://github.com/nirgluzman/AWS-Gofore-Parking-User.git (User frontend)
- https://github.com/nirgluzman/AWS-Gofore-Parking-Admin.git (Admin frontend)

## References

- https://serverlessland.com/
- https://github.com/aws-samples/serverless-patterns/tree/main/apigw-lambda-dynamodb-terraform
- https://github.com/hashicorp/terraform-provider-aws.git

## AWS API Gateway

- https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-basic-concept.html
- https://digitalcloud.training/amazon-api-gateway/

## Building Lambda functions with TypeScript

- https://docs.aws.amazon.com/lambda/latest/dg/lambda-typescript.html
- https://www.totaltypescript.com/build-a-node-app-with-typescript-and-esbuild
- https://docs.aws.amazon.com/lambda/latest/dg/nodejs-package.html

## Amazon Cognito for User AuthN, AuthZ and access to AWS resources

### User Pools = User Directory

- Manages user identities and authentication.
- Stores user data, handles login/signup, and manages authentication.

### User Pool Client = Application Access Key

- `Clients` - applications (web apps, mobile apps) interact with User Pools through User Pool
  Clients. Clients request specific scopes to gain access to resources.
- `Scopes` are permissions that we grant to an application (User Pool Client) to control what
  resources or data the application can access on behalf of a user (authZ). I.e., what an
  application is allowed to do after a user has authenticated. The backend checks the access token
  (which contains the scopes) to determine if the request should be allowed.
- Examples for scopes:
  - User profile data stored in application's database.
  - Access to specific features or functionalities within the application.
  - Data served by your application's API.
- `Client ID` - identifies the application - it uniquely identifies the application that's trying to
  access the User Pool. Each application gets its own Client ID - a specific application's "key" to
  access the User Pool.
- `Client Secret` - for added security, some clients have a secret key that the application uses to
  authenticate itself when interacting with the User Pool.

### Identity Pools = Access to AWS Resources (permissions to AWS infrastructure)

- Provides temporary AWS credentials (access keys, secret key, session token) to users so they can
  interact with AWS services. These credentials are tied to IAM roles and policies, which define
  what AWS resources the user can access.
