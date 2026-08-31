-- ####################################################
-- Storage integration (module 7) - phase 1 of the AWS<->Snowflake
-- trust handshake. You haven't shared the course's exact statement for
-- this part yet, so this follows the same naming convention as your other
-- objects (DEA_REAL_TIME_SCD1_*) - swap in the course's exact wording if
-- it differs once you get to this module.
--
-- STORAGE_AWS_ROLE_ARN = the `snowflake_integration_role_arn` Terraform
-- output (the second IAM role - "dea-real-time-scd1-snowflake-role").
-- ####################################################

USE ROLE ACCOUNTADMIN;
USE DATABASE DEA_REAL_TIME_SCD1;

CREATE STORAGE INTEGRATION IF NOT EXISTS DEA_REAL_TIME_SCD1_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = '<PASTE snowflake_integration_role_arn TERRAFORM OUTPUT HERE>'
  STORAGE_ALLOWED_LOCATIONS = ('s3://<PASTE data bucket name HERE>/raw/');

-- Reveals STORAGE_AWS_IAM_USER_ARN + STORAGE_AWS_EXTERNAL_ID. Copy both
-- into terraform.tfvars (snowflake_iam_user_arn / snowflake_external_id),
-- then `terraform apply` again - phase 2, updates only the IAM role's
-- trust policy.
DESC INTEGRATION DEA_REAL_TIME_SCD1_INTEGRATION;
