-- SOME OF THE COMMANDS USED TO SETUP THE PIPELINE

-- Create warehouse
CREATE OR REPLACE WAREHOUSE DEFAULTWH
WITH WAREHOUSE_SIZE = 'XSMALL'
AUTO_SUSPEND = 300
AUTO_RESUME = TRUE
INITIALLY_SUSPENDED = TRUE;

-- Create storage integration
-- Requires the ACCOUNTADMIN role
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE STORAGE INTEGRATION S3EVENTS
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::885064221325:role/zentral-snowflake'
  STORAGE_ALLOWED_LOCATIONS = ('s3://zentral-sensibly-nice-anchovy/data/');

-- Get the integration information
-- The trust relationship of the AWS role with S3 access
-- will need to be updated.
DESC INTEGRATION S3EVENTS;

-- Create database
CREATE DATABASE IF NOT EXISTS ZENTRAL
DATA_RETENTION_TIME_IN_DAYS = 1
MAX_DATA_EXTENSION_TIME_IN_DAYS = 1;

-- Create Stage
USE SCHEMA ZENTRAL.PUBLIC;
CREATE OR REPLACE STAGE ZENTRALPARQUETEVENTS
  URL = 's3://zentral-sensibly-nice-anchovy/data/'
  STORAGE_INTEGRATION = S3EVENTS;

-- list the files in the stage
LIST @ZENTRALPARQUETEVENTS;

-- create destination table
CREATE OR REPLACE TABLE ZENTRALEVENTS
(
  TYPE VARCHAR(256),
  CREATED_AT TIMESTAMP,
  TAGS ARRAY,
  PROBES ARRAY,
  OBJECTS ARRAY,
  METADATA VARIANT,
  PAYLOAD VARIANT,
  SERIAL_NUMBER VARCHAR(256)
);

-- create the pipe by loading formatted data
CREATE OR REPLACE PIPE ZENTRAL.PUBLIC.ZENTRALEVENTS
auto_ingest = true
AS COPY INTO ZENTRAL.PUBLIC.ZENTRALEVENTS(
  TYPE,
  CREATED_AT,
  TAGS,
  PROBES,
  OBJECTS,
  METADATA,
  PAYLOAD,
  SERIAL_NUMBER
) FROM (
  SELECT
  $1:type::varchar,
  $1:created_at::timestamp_ntz,
  $1:tags::array,
  $1:probes::array,
  $1:objects::array,
  PARSE_JSON($1:metadata),
  PARSE_JSON($1:payload),
  $1:serial_number::varchar
  FROM @ZENTRAL.PUBLIC.ZENTRALPARQUETEVENTS
)
file_format = (type = 'PARQUET');

-- Get the SQS queue ARN for the notifications
DESCRIBE PIPE ZENTRAL.PUBLIC.ZENTRALEVENTS;

-- explore the parquet files
SELECT
$1:type::varchar,
$1:created_at::timestamp_ntz,
$1:serial_number::varchar,
$1:tags::array,
$1:probes::array,
$1:objects::array,
PARSE_JSON($1:metadata),
PARSE_JSON($1:payload),
$1:serial_number::varchar
FROM @ZENTRALPARQUETEVENTS
LIMIT 1;

-- load historic data
ALTER PIPE ZENTRAL.PUBLIC.ZENTRALEVENTS REFRESH;

-- check pipe status
SELECT SYSTEM$PIPE_STATUS('ZENTRAL.PUBLIC.ZENTRALEVENTS');

-- load the data 
USE WAREHOUSE DEFAULTWH;
SELECT * FROM ZENTRAL.PUBLIC.ZENTRALEVENTS order by CREATED_AT desc limit 10;

--
SELECT type, count(*) from ZENTRALEVENTS where created_at > '2022-10-24'
group by type order by count(*) desc;

--
SELECT serial_number, COUNT(*) FROM ZENTRALEVENTS
WHERE serial_number IS NOT NULL
AND created_at > '2022-08-16'
GROUP BY serial_number
ORDER BY COUNT(*) DESC;

-- create read only user for ZENTRALEVENTS table
-- create role
create role if not exists ZENTRALRO;
grant usage on warehouse DEFAULTWH to role ZENTRALRO;
grant usage on schema ZENTRAL.PUBLIC to role ZENTRALRO;
grant usage on database ZENTRAL to role ZENTRALRO;
grant select on ZENTRAL.PUBLIC.ZENTRALEVENTS to role ZENTRALRO;
-- create user
create user if not exists ZENTRALRO
password = 'dwjkhd2lhbewljhdbewjh';
-- grant role to user;
grant role ZENTRALRO to user ZENTRALRO;
grant role ZENTRALRO to user ACCOUNTADMIN;

--
SELECT CREATED_AT, PAYLOAD:source.name::varchar FROM ZENTRALEVENTS WHERE type = 'inventory_heartbeat';

SELECT TYPE, MAX(CREATED_AT) LAST_SEEN, PAYLOAD:source.name::varchar SOURCE_NAME, NULL USER_AGENT
FROM ZENTRALEVENTS
WHERE TYPE='inventory_heartbeat'
AND SERIAL_NUMBER='C07FR1U1Q6P0'
GROUP BY TYPE, SOURCE_NAME, USER_AGENT

UNION

SELECT TYPE, MAX(CREATED_AT) LAST_SEEN, NULL SOURCE_NAME, METADATA:request.user_agent::varchar USER_AGENT
FROM ZENTRALEVENTS
WHERE TYPE <> 'inventory_heartbeat'
AND ARRAY_CONTAINS('heartbeat'::variant, TAGS)
AND SERIAL_NUMBER='C07FR1U1Q6P0'
GROUP BY TYPE, SOURCE_NAME, USER_AGENT;

SELECT COUNT(*) EVENT_COUNT, COUNT(DISTINCT SERIAL_NUMBER) MACHINE_COUNT,
DATE_TRUNC('DAY', CREATED_AT) BUCKET
FROM ZENTRALEVENTS
WHERE ARRAY_CONTAINS('osquery'::variant, TAGS)
GROUP BY BUCKET ORDER BY BUCKET DESC;

-- session timeout?
select STATEMENT_TIMEOUT_IN_SECONDS;
