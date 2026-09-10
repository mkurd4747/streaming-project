variable "project_name" {
  description = "Short name used as a prefix for every resource (lowercase, hyphens only)."
  type        = string
  default     = "end-to-end-streaming"
}

variable "environment" {
  description = "Environment tag, e.g. dev, learning, prod."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}


# ---------------------------------------------------------------------------

variable "snowflake_iam_user_arn" {
  description = "STORAGE_AWS_IAM_USER_ARN from `DESC INTEGRATION s3_streaming_integration;` in Snowflake. Placeholder until phase 2."
  type        = string
  default     = "arn:aws:iam::135245989911:root"
}

variable "snowflake_external_id" {
  description = "STORAGE_AWS_EXTERNAL_ID from `DESC INTEGRATION s3_streaming_integration;` in Snowflake. Placeholder until phase 2."
  type        = string
  default     = "PLACEHOLDER_EXTERNAL_ID_0000"
}

variable "snowpipe_sqs_arn" {
  description = "notification_channel ARN from `DESC PIPE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE;` in Snowflake. Placeholder until phase 2 (used to wire S3 event notifications to Snowpipe auto-ingest)."
  type        = string
  default     = ""
}
