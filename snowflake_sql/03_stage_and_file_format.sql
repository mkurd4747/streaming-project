-- ####################################################
-- External stage (module 7) - not verbatim from the course (you haven't
-- shared this exact script yet), but consistent with the naming you've
-- used elsewhere. The Snowpipe script (04) references this stage as
-- DEA_REAL_TIME_SCD1.RAW.DEA_REAL_TIME_SCD1_STAGE - keep that name if you
-- want 04 to work without edits.
-- ####################################################

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA DEA_REAL_TIME_SCD1.RAW;

CREATE STAGE IF NOT EXISTS DEA_REAL_TIME_SCD1_STAGE
  URL = 's3://<PASTE data bucket name HERE>/raw/'
  STORAGE_INTEGRATION = DEA_REAL_TIME_SCD1_INTEGRATION;

-- Sanity check once test data has been sent through the pipeline:
LIST @DEA_REAL_TIME_SCD1_STAGE;
