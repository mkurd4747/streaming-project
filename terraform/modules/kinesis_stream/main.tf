resource "aws_kinesis_stream" "this" {
  name             = "${var.project_name}-stream"
  shard_count      = var.shard_count
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}
