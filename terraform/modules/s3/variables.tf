variable "project_name" {
  type = string
}

variable "snowpipe_sqs_arn" {
  description = "SQS queue ARN from `DESC PIPE`. Empty string until phase 2."
  type        = string
  default     = ""
}
