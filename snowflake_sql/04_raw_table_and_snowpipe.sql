-- ###########################
-- Code to Setup the Snowpipe   (module 8 - as given by the course)
-- ###########################

--Setup the Role as ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;

--Setup the Warehouse as COMPUTE_WH
USE WAREHOUSE COMPUTE_WH;

--Use the RAW Schema
USE SCHEMA DEA_REAL_TIME_SCD1.RAW;

--Create the Employee RAW Table
CREATE OR REPLACE TABLE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_RAW
(
JSON_DATA VARIANT
);

--Setup the Snowpipe to load RAW table from S3 bucket
CREATE OR REPLACE PIPE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE
AUTO_INGEST = TRUE AS
COPY INTO DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_RAW
FROM @DEA_REAL_TIME_SCD1.RAW.DEA_REAL_TIME_SCD1_STAGE
FILE_FORMAT = (TYPE = 'JSON');

--Show the Pipes
SHOW PIPES;

--Check the Status of the Snowpipe
SELECT SYSTEM$PIPE_STATUS('DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE');

-- After creating the pipe, run DESC PIPE and copy `notification_channel`
-- into terraform.tfvars as snowpipe_sqs_arn, then `terraform apply` again
-- - this wires the S3 event notification that actually triggers Snowpipe.
DESC PIPE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE;
