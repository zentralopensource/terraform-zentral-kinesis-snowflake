# Zentral Kinesis Snowflake Terraform module

See [Snowflake documentation](https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3.html).

This repository contains a Terraform module to setup an [AWS Kinesis Data Firehose](https://aws.amazon.com/kinesis/data-firehose/) to process Zentral events. The events will be serialized as Parquet files in a S3 bucket. Snowflake will be notified of the creation of each parquet file, and a Snowflake PIPE will be allowed to ingest them.
