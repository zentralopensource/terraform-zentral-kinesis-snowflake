// configure AWS provider
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE>"
  }
}

module "firehose" {
  source   = "https://github.com/zentralopensource/terraform-zentral-kinesis-snowflake.git/?ref=v0.1.0"
  basename = "Zentral"


  // A S3 lifecycle policy will be configured to delete the parquet files after 3 days
  parquet_files_retention_days = 3

  // Buffer incoming data to the specified size, in MBs, before delivering it to S3.
  firehose_buffer_size = 64
  // Buffer incoming data for the specified period of time, in seconds, before delivering it to S3.
  firehose_buffer_interval = 120

  // ARN of the AWS principal trusted to assume the role configured to put Kinesis records
  kinesis_client_trusted_arn = "arn:aws:iam::<ACCOUNT_ID>:role/<ROLE>"

  // ARN of the Snowflake account AWS user & external ID needed to establish a trust relationship with the Snowflake role
  // See Snowflake STORAGE INTEGRATION
  snowflake_user_arn    = "arn:aws:iam::<ACCOUNT_ID>:user/<USERNAME>"
  snowflake_external_id = "<EXTERNAL_ID>"

  // ARN of the Snowflake SQS queue that needs to receive the ObjectCreate notifications
  // See Snowflake PIPE
  snowflake_sqs_queue_arn = "arn:aws:sqs:us-east-1:<ACCOUNT_ID>:<QUEUE>"

  // DANGER !!! Only use it for testing
  destroy_all_resources = true
}
