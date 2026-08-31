output "stream_name" {
  value = aws_kinesis_firehose_delivery_stream.this.name
}

output "stream_arn" {
  value = aws_kinesis_firehose_delivery_stream.this.arn
}
