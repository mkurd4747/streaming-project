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
