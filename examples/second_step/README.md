# Second step example

To setup the ingestion of the Zentral events in Snowflake via a Kinesis Firehose, we need to proceed in two steps (see [first step](../first_step) if you haven't already).

Once the Snowflake `STORAGE INTEGRATION` and `PIPE` have been configured, you can add the following arguments:

* `snowflake_user_arn`
* `snowflake_external_id`
* `snowflake_sqs_queue_arn`

You can then apply the terraform configuration.
