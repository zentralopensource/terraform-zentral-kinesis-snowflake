data "aws_iam_policy_document" "kinesis_client" {
  statement {
    actions = [
      "kinesis:PutRecord",
      "kinesis:PutRecords",
    ]
    resources = [
      aws_kinesis_stream.zentral-events.arn
    ]
  }
}

resource "aws_iam_policy" "kinesis_client" {
  name   = "${local.namespace}-kinesis-client"
  policy = data.aws_iam_policy_document.kinesis_client.json
}

data "aws_iam_policy_document" "kinesis_client_trust" {
  count = var.kinesis_client_trusted_arn == null ? 0 : 1

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.kinesis_client_trusted_arn]
    }
  }
}

resource "aws_iam_role" "kinesis_client" {
  count = var.kinesis_client_trusted_arn == null ? 0 : 1

  name        = "${local.namespace}-kinesis-client"
  description = "The role to assume to be able to put Kinesis records"

  assume_role_policy = data.aws_iam_policy_document.kinesis_client_trust[0].json
}


resource "aws_iam_role_policy_attachment" "kinesis_client" {
  count = var.kinesis_client_trusted_arn == null ? 0 : 1

  role       = aws_iam_role.kinesis_client[0].name
  policy_arn = aws_iam_policy.kinesis_client.arn
}
