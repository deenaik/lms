provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lms_lambda_role" {
  name = "lms_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lms_lambda_role.name
}

# Package and upload the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../backend/lms_api.py"
  output_path = "lms_api.zip"
}

resource "aws_lambda_function" "lms_api" {
  function_name = "lmsapi"
  handler       = "lms_api.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lms_lambda_role.arn

  filename = data.archive_file.lambda_zip.output_path
}

# Create API Gateway REST API
resource "aws_api_gateway_rest_api" "lms_api" {
  name = "LmsAPIGateway"
}

# Create API Gateway resource
resource "aws_api_gateway_resource" "lms_resource" {
  rest_api_id = aws_api_gateway_rest_api.lms_api.id
  parent_id   = aws_api_gateway_rest_api.lms_api.root_resource_id
  path_part   = "lmsresource"
}

# Create API Gateway method
resource "aws_api_gateway_method" "lms_method" {
  rest_api_id   = aws_api_gateway_rest_api.lms_api.id
  resource_id   = aws_api_gateway_resource.lms_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Create API Gateway integration
resource "aws_api_gateway_integration" "lms_integration" {
  rest_api_id = aws_api_gateway_rest_api.lms_api.id
  resource_id = aws_api_gateway_resource.lms_resource.id
  http_method = aws_api_gateway_method.lms_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lms_api.invoke_arn
}

# Grant API Gateway permission to invoke Lambda function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lms_api.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.lms_api.execution_arn}/*/*"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "lms_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lms_api.id
  stage_name  = "prod"

  # Ensure the deployment updates when the API configuration changes
  triggers = {
    redeployment = sha1(
      jsonencode(
        aws_api_gateway_integration.lms_integration
      )
    )
  }

  depends_on = [
    aws_api_gateway_integration.lms_integration,
  ]
}

