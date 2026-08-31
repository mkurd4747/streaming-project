variable "project_name" {
  type = string
}

variable "lambda_invoke_arn" {
  type = string
}

variable "stage_name" {
  type    = string
  default = "dev"
}
