-- ##################################
-- Code to Stop the Snowflake objects   (as given by the course)
-- ##################################
-- This PAUSES the pipe/task (no data loss - Snowpipe just stops
-- processing new files, the task stops running) without dropping
-- anything. Use this between test sessions, or whenever you want to stop
-- burning warehouse credits, without tearing down the whole pipeline.
-- For full teardown (course module 14), see 08_teardown.sql instead.

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Alter the Snowpipe to pause
ALTER PIPE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE SET PIPE_EXECUTION_PAUSED = TRUE;

--Check the Status of the Snowpipe
SELECT SYSTEM$PIPE_STATUS('DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE');

--Alter the TASK to Suspend
ALTER TASK DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_TASK SUSPEND;

--Show TASKS
SHOW TASKS;

-- To resume later:
-- ALTER PIPE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE SET PIPE_EXECUTION_PAUSED = FALSE;
-- ALTER TASK DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_TASK RESUME;
