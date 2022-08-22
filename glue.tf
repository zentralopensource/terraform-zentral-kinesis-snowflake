resource "aws_glue_catalog_database" "db" {
  name = local.namespace
}

# reference https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-catalog-tables.html
resource "aws_glue_catalog_table" "table" {
  name          = "${local.namespace}-events"
  database_name = aws_glue_catalog_database.db.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
    "EXTERNAL"       = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data.id}/data/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "${local.namespace}-events"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
        "parquet.compression"  = "SNAPPY"
      }
    }

    columns {
      name    = "type"
      type    = "string"
      comment = "Event type"
    }
    columns {
      name    = "created_at"
      type    = "timestamp"
      comment = "Event timestamp"
    }
    columns {
      name    = "tags"
      type    = "array<string>"
      comment = "List of event tags"
    }
    columns {
      name    = "probes"
      type    = "array<int>"
      comment = "List of probe primary keys"
    }
    columns {
      name    = "objects"
      type    = "array<string>"
      comment = "List of linked object references"
    }
    columns {
      name    = "metadata"
      type    = "string"
      comment = "Event metadata in JSON format"
    }
    columns {
      name    = "payload"
      type    = "string"
      comment = "Event payload in JSON format"
    }
    columns {
      name    = "serial_number"
      type    = "string"
      comment = "Machine serial number"
    }
  }
}
