
output "shared_role_arn" {
  value = aws_iam_role.shared.arn
}

output "snowflake_integration_role_arn" {
  value = aws_iam_role.snowflake_integration.arn
}
