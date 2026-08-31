data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/build/handler.zip"
}

resource "aws_lambda_function" "ingest" {
  function_name = "${var.project_name}-ingest"
  role          = var.lambda_role_arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 15
  memory_size   = 256

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      KINESIS_STREAM_NAME = var.kinesis_stream_name
      ERROR_BUCKET_NAME   = var.error_bucket_name
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.ingest.function_name}"
  retention_in_days = 14
}

# NOTE: the aws_lambda_permission that lets API Gateway invoke this function
# lives in the ROOT module (main.tf), not here. Reason: that permission
# needs this module's function_name AND the api_gateway module's
# execution_arn, while the api_gateway module needs this module's
# invoke_arn to build its integration. Putting the permission in either
# module would create a module-level dependency cycle, so it's wired up
# one level up where both outputs are already available.
