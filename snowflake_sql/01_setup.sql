-- ####################################################
-- Setup - as given by the course (module 7)
-- ####################################################

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

CREATE OR REPLACE DATABASE DEA_REAL_TIME_SCD1;

USE DATABASE DEA_REAL_TIME_SCD1;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS TRANSFORMED;
