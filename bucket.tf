# Random name for the S3 bucket
resource "random_pet" "s3_data_bucket_mame" {
  length = 3
}

# S3 bucket to be used as data lake
resource "aws_s3_bucket" "data" {
  bucket = "${local.namespace}-${random_pet.s3_data_bucket_mame.id}"

  # DANGER !!!
  force_destroy = var.destroy_all_resources
}

# block public access to the S3 bucket 1/2
resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "private"
}

# block public access to the S3 bucket 2/2
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# setup default SSE for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket logging configuration
resource "aws_s3_bucket_logging" "data" {
  count = var.logging_bucket_id == null ? 0 : 1

  bucket        = aws_s3_bucket.data.id
  target_bucket = var.logging_bucket_id
  target_prefix = aws_s3_bucket.data.id
}

# S3 lifecycle policy
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  count = var.parquet_files_retention_days == null ? 0 : 1

  bucket = aws_s3_bucket.data.id

  rule {
    id = "expire_parquet_files"

    filter {
      prefix = "data/"
    }

    expiration {
      days = var.parquet_files_retention_days
    }

    status = "Enabled"
  }
}

# S3 ObjectCreate notifications
resource "aws_s3_bucket_notification" "snowflake" {
  count = var.snowflake_sqs_queue_arn == null ? 0 : 1

  bucket = aws_s3_bucket.data.id

  queue {
    queue_arn     = var.snowflake_sqs_queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "data/"
  }
}
