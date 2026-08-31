resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${var.project_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_stream" "firehose_delivery" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = "${var.project_name}-firehose"
  destination = "extended_s3"

  # Firehose pulls from the Kinesis Data Stream rather than receiving
  # PutRecord calls directly - matches the Lambda -> Kinesis Stream ->
  # Firehose -> S3 flow in the architecture diagram.
  kinesis_source_configuration {
    kinesis_stream_arn = var.kinesis_stream_arn
    role_arn            = var.firehose_role_arn
  }

  extended_s3_configuration {
    role_arn   = var.firehose_role_arn
    bucket_arn = var.data_bucket_arn

    prefix              = "raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    # 1MB/60s while learning so records show up in S3 almost immediately;
    # bump to something like 128MB/300s for a real workload to cut down on
    # small-file overhead in S3/Snowpipe.
    buffering_size     = 1
    buffering_interval = 60

    compression_format = "UNCOMPRESSED" # Snowpipe's JSON file format reads
    # this directly; switch to GZIP for production and set COMPRESSION =
    # AUTO on the Snowflake file format if you do.

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_delivery.name
    }
  }
}
