resource "aws_kinesis_stream" "zentral-events" {
  name = "${local.namespace}-events"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }
}

locals {
  firehose_name = "${local.namespace}-events-s3"
}

data "aws_iam_policy_document" "firehose" {
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*"
    ]
  }

  statement {
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards"
    ]
    resources = [
      aws_kinesis_stream.zentral-events.arn
    ]
  }

  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"

    ]
    resources = [
      aws_glue_catalog_database.db.arn,
      aws_glue_catalog_table.table.arn,
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog", # glue:GetTableVersions
    ]
  }

  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/${local.firehose_name}:log-stream:*"
    ]
  }
}

resource "aws_iam_policy" "firehose" {
  name   = "${local.namespace}-firehose"
  policy = data.aws_iam_policy_document.firehose.json
}

data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name               = "${local.namespace}-firehose"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

resource "aws_kinesis_firehose_delivery_stream" "zentral-events-s3" {
  name        = local.firehose_name
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.zentral-events.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.data.arn

    buffer_size         = var.firehose_buffer_size
    buffer_interval     = var.firehose_buffer_interval
    prefix              = "data/!{timestamp:yyyy/MM/dd/}"
    error_output_prefix = "!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd/}"

    data_format_conversion_configuration {
      enabled = true

      input_format_configuration {
        deserializer {
          hive_json_ser_de { // this ser/der allows custom timestamp formats
            timestamp_formats = [
              "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
              "yyyy-MM-dd'T'HH:mm:ss.SSS",
              "yyyy-MM-dd'T'HH:mm:ss"
            ]
          }
        }
      }

      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.table.database_name
        table_name    = aws_glue_catalog_table.table.name
        role_arn      = aws_iam_role.firehose.arn
      }
    }
  }
}
