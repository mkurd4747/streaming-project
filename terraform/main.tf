module "s3" {
  source = "./modules/s3"

  project_name     = var.project_name
  snowpipe_sqs_arn = var.showtime_sqs_arn
}

module "kinesis_stream" {
  source = "./modules/kinesis_stream"

  project_name = var.project_name
}

module "iam" {
  source = "./modules/iam"

  project_name           = var.project_name
  snowflake_iam_user_arn = var.snowflake_iam_user_arn
  snowflake_external_id  = var.snowflake_external_id
}
module "firehose" {
  source = "./modules/firehose"

  project_name       = var.project_name
  firehose_role_arn  = module.iam.shared_role_arn
  data_bucket_arn    = module.s3.data_bucket_arn
  kinesis_stream_arn = module.kinesis_stream.stream_arn
}

module "lambda" {
  source = "./modules/lambda"

  project_name        = var.project_name
  lambda_source_dir   = "${path.module}/../lambda_src"
  lambda_role_arn     = module.iam.shared_role_arn
  kinesis_stream_name = module.kinesis_stream.stream_name
  error_bucket_name   = module.s3.error_bucket_name
}

module "api_gateway" {
  source = "./modules/api_gateway"

  project_name      = var.project_name
  lambda_invoke_arn = module.lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"
}
