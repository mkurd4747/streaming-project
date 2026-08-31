output "data_bucket_name" {
  value = aws_s3_bucket.data.bucket
}

output "data_bucket_arn" {
  value = aws_s3_bucket.data.arn
}

output "error_bucket_name" {
  value = aws_s3_bucket.errors.bucket
}

output "error_bucket_arn" {
  value = aws_s3_bucket.errors.arn
}
