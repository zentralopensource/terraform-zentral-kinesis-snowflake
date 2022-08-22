data "aws_iam_policy_document" "snowflake_s3" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "${aws_s3_bucket.data.arn}/data/*"
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      aws_s3_bucket.data.arn,
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["data/*"]
    }
  }
}

resource "aws_iam_policy" "snowflake_s3" {
  name   = "${local.namespace}-snowflake-s3"
  policy = data.aws_iam_policy_document.snowflake_s3.json
}


data "aws_iam_policy_document" "snowflake_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      // self while waiting for the Snowflake AWS user ARN
      identifiers = [var.snowflake_user_arn == null ? data.aws_caller_identity.current.arn : var.snowflake_user_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      // UNKNOWN while waiting for the Snowflake External ID
      values = [var.snowflake_external_id == null ? "UNKNOWN" : var.snowflake_external_id]
    }
  }
}

resource "aws_iam_role" "snowflake" {
  name        = "${local.namespace}-snowflake"
  description = "The role assumed by snowflake to read the data in the S3 bucket"

  assume_role_policy = data.aws_iam_policy_document.snowflake_role_trust.json
}

resource "aws_iam_role_policy_attachment" "snowflake_s3" {
  role       = aws_iam_role.snowflake.name
  policy_arn = aws_iam_policy.snowflake_s3.arn
}
