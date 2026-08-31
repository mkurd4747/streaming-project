-- ###################################################
-- Code to check the Snowflake objects before the test   (module 11, as given)
-- ###################################################

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

--Check the Status of the Snowpipe
SELECT SYSTEM$PIPE_STATUS('DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_PIPE');

--Alter the TASK to Resume/Suspend
ALTER TASK DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_TASK RESUME;

--Show TASKS
SHOW TASKS;

--Check the data in the Employee RAW Table
SELECT * FROM DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_RAW;

--Check the data in the Employee Stream
SELECT * FROM DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_STREAM;

--Check the data in the Employee TRANSFORMED Table
SELECT * FROM DEA_REAL_TIME_SCD1.TRANSFORMED.EMPLOYEE_TRANSFORMED ORDER BY UPDATE_DTS DESC;

--Check the status of the TASK
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'EMPLOYEE_SCD1_TASK'
    )
)
ORDER BY SCHEDULED_TIME DESC;
