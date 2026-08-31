variable "project_name" {
  description = "Short name used as a prefix for every resource (lowercase, hyphens only)."
  type        = string
  default     = "de-academy-streaming"
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
# Phase 2 variables: these come FROM Snowflake and don't exist until you've
# run 03_storage_integration.sql and 05_snowpipe.sql and read back their
# output with DESC INTEGRATION / DESC PIPE. Leave the defaults as-is for the
# first `terraform apply`, then fill these in via terraform.tfvars and run
# `terraform apply` again. See the root README for the exact steps.
# ---------------------------------------------------------------------------

variable "snowflake_iam_user_arn" {
  description = "STORAGE_AWS_IAM_USER_ARN from `DESC INTEGRATION s3_streaming_integration;` in Snowflake. Placeholder until phase 2."
  type        = string
  default     = "arn:aws:iam::000000000000:user/placeholder-snowflake-user"
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
