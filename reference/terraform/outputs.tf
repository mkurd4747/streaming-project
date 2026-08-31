output "api_invoke_url" {
  description = "POST here from Postman - this is the front door of the pipeline."
  value       = module.api_gateway.invoke_url
}

output "data_bucket_name" {
  value = module.s3.data_bucket_name
}

output "error_bucket_name" {
  value = module.s3.error_bucket_name
}

output "kinesis_stream_name" {
  value = module.kinesis_stream.stream_name
}

output "firehose_stream_name" {
  value = module.firehose.stream_name
}

output "lambda_function_name" {
  value = module.lambda.function_name
}

output "snowflake_integration_role_arn" {
  description = "Feed this to Snowflake's CREATE STORAGE INTEGRATION statement (STORAGE_AWS_ROLE_ARN)."
  value       = module.iam.snowflake_integration_role_arn
}
