terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "test-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  force_destroy = true
}

data "archive_file" "lambda_test_terraform" {
  type = "zip"

  source_dir  = "${path.module}/lambda-function"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_s3_object" "lambda_test_terraform" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda_function.zip"
  source = data.archive_file.lambda_test_terraform.output_path

  etag = filemd5(data.archive_file.lambda_test_terraform.output_path)
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "lambda_handler"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_test_terraform.key

  runtime = "python3.9"
  handler = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda_test_terraform.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "test_terraform" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_sns_topic" "test_terraform"{
  name="test_terraform"

}

data "aws_iam_policy_document" "lambda_to_sns"{
  statement {
    sid=""
    effect="Allow"
    actions=[
      "sns:Publish"
    ]
    resources=[
      aws_sns_topic.test_terraform.arn
    ]

  } 
}

resource "aws_iam_policy" "lambda_to_sns"{
  name="lambda_to_sns"
  path="/"
  policy=data.aws_iam_policy_document.lambda_to_sns.json
}

resource "aws_iam_role_policy_attachment" "lambda_to_sns_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_to_sns.arn
}

resource "aws_api_gateway_rest_api" "lambda" {
  name          = "serverless_lambda_gw"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "calc"
  parent_id   = aws_api_gateway_rest_api.lambda.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.lambda.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {"method.request.querystring.Key1" = true,
                         "method.request.querystring.Key2" = true}
}

resource "aws_api_gateway_integration" "test_terraform" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  resource_id = aws_api_gateway_resource.resource.id 
  http_method = aws_api_gateway_method.method.http_method

  uri    = aws_lambda_function.lambda_function.invoke_arn
  type   = "AWS"
  integration_http_method = "POST"

  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_parameters = {
    "integration.request.querystring.Key1":"method.request.querystring.Key1",
    "integration.request.querystring.Key2":"method.request.querystring.Key2"
  }
}

resource "aws_api_gateway_deployment" "test_terraform" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.resource.id,
      aws_api_gateway_method.method.id,
      aws_api_gateway_integration.test_terraform.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "test_terraform" {
  deployment_id = aws_api_gateway_deployment.test_terraform.id
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  stage_name    = "Test"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.lambda.execution_arn}/*/*"
}