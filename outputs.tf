# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda_function.function_name
}

output "sns_arn" {
  
  description = "Name of the Lambda function."

  value = aws_sns_topic.test_terraform.arn
  
}

output "api_url" {
  
  description = "Name of the Lambda function."

  value = aws_api_gateway_stage.test_terraform.invoke_url
  
}