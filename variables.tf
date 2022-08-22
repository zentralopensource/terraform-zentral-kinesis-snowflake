variable "basename" {
  default = "Zentral"
}

variable "destroy_all_resources" {
  description = "Toggle force destroy on compatible resources."
  default     = false
}

variable "logging_bucket_id" {
  description = "ID of the bucket used to store the access logs of the data bucket. Defaults to null → no logs."
  default     = null
}

variable "parquet_files_retention_days" {
  description = "If set, a S3 lifecycle policy will be configured to delete the parquet files after N days."
  type        = number
  default     = null
}

variable "firehose_buffer_size" {
  description = "Buffer incoming data to the specified size, in MBs, before delivering it to S3."
  default     = 64
}

variable "firehose_buffer_interval" {
  description = "Buffer incoming data for the specified period of time, in seconds, before delivering it to S3."
  default     = 120
}

variable "kinesis_client_trusted_arn" {
  description = "ARN of the AWS principal trusted to assume the role configured to put Kinesis records."
  type        = string
  default     = null
}

variable "snowflake_user_arn" {
  description = "ARN of the Snowflake account AWS user"
  type        = string
  default     = null
}

variable "snowflake_external_id" {
  description = "The external ID needed to establish a trust relationship with the Snowflake role"
  type        = string
  default     = null
}

variable "snowflake_sqs_queue_arn" {
  description = "ARN of the Snowflake SQS queue that needs to receive the ObjectCreate notifications"
  type        = string
  default     = null
}
