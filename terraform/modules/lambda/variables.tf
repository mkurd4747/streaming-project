variable "project_name" {
  type = string
}

variable "lambda_source_dir" {
  description = "Path to the directory containing handler.py"
  type        = string
}

variable "lambda_role_arn" {
  type = string
}

variable "kinesis_stream_name" {
  type = string
}

variable "error_bucket_name" {
  type = string
}
