# Kinesis Data Stream sitting between Lambda (producer) and Firehose
# (consumer). Lambda calls PutRecord on this stream for every valid record;
# Firehose is configured with a KinesisStreamSourceConfiguration that reads
# from it and batches records into S3.
#
# Why a stream AND a Firehose instead of Lambda -> Firehose directly? This
# mirrors the course architecture and gives you a real Kinesis Data Streams
# shard you can inspect (GetRecords, shard iterators, CloudWatch
# IncomingRecords/IteratorAge metrics) - useful for learning how streaming
# ingestion + buffering behave independently of the S3 delivery layer.

resource "aws_kinesis_stream" "this" {
  name             = "${var.project_name}-stream"
  shard_count      = var.shard_count
  retention_period = 24 # hours - default minimum, plenty for a learning project

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}
