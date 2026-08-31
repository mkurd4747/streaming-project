resource "random_id" "suffix" {
  byte_length = 3
}

# --- Data bucket (Firehose destination / Snowpipe source) ------------------

resource "aws_s3_bucket" "data" {
  bucket = "${var.project_name}-data-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket                  = aws_s3_bucket.data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "expire-raw-data"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Phase-2 only: wires S3 "new object" events on the data bucket to the SQS
# queue Snowpipe creates for auto-ingest. Skipped until snowpipe_sqs_arn is
# set, so the phase-1 apply doesn't fail.
resource "aws_s3_bucket_notification" "snowpipe_auto_ingest" {
  count  = var.snowpipe_sqs_arn != "" ? 1 : 0
  bucket = aws_s3_bucket.data.id

  queue {
    queue_arn     = var.snowpipe_sqs_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "raw/"
  }
}

# --- Error bucket (Lambda writes invalid records directly here) ------------

resource "aws_s3_bucket" "errors" {
  bucket = "${var.project_name}-errors-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "errors" {
  bucket = aws_s3_bucket.errors.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "errors" {
  bucket                  = aws_s3_bucket.errors.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "errors" {
  bucket = aws_s3_bucket.errors.id

  rule {
    id     = "expire-error-records"
    status = "Enabled"

    filter {
      prefix = "invalid/"
    }

    expiration {
      days = 30
    }
  }
}
