locals {
  shared_role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
  ]
}

# --- Role 1: shared by API Gateway, Lambda, and Firehose -------------------

data "aws_iam_policy_document" "shared_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "apigateway.amazonaws.com",
        "lambda.amazonaws.com",
        "firehose.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "shared" {
  name               = "${var.project_name}-aws-role"
  assume_role_policy = data.aws_iam_policy_document.shared_assume.json
}

resource "aws_iam_role_policy_attachment" "shared" {
  for_each   = toset(local.shared_role_managed_policy_arns)
  role       = aws_iam_role.shared.name
  policy_arn = each.value
}

# --- Role 2: Snowflake storage-integration role -----------------------------
# See main.tf's header comment (in the skeleton) for the two-phase-apply
# explanation of why the trust policy below starts out pointing at
# placeholder values.

data "aws_iam_policy_document" "snowflake_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.snowflake_iam_user_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.snowflake_external_id]
    }
  }
}

resource "aws_iam_role" "snowflake_integration" {
  name               = "${var.project_name}-snowflake-role"
  assume_role_policy = data.aws_iam_policy_document.snowflake_assume.json
}

resource "aws_iam_role_policy_attachment" "snowflake_integration_s3" {
  role       = aws_iam_role.snowflake_integration.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
