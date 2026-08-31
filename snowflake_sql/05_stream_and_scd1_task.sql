-- ###############################
-- Code to Setup the Stream & Task   (module 9 - as given by the course)
-- ###############################

--Setup the Role as ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;

--Setup the Warehouse as COMPUTE_WH
USE WAREHOUSE COMPUTE_WH;

--Use the RAW Schema
USE SCHEMA DEA_REAL_TIME_SCD1.RAW;

--Create the Employee RAW Stream
CREATE OR REPLACE STREAM DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_STREAM
ON TABLE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_RAW;

--Create the Employee TRANSFORMED Table
CREATE OR REPLACE TABLE DEA_REAL_TIME_SCD1.TRANSFORMED.EMPLOYEE_TRANSFORMED
(
EMPLOYEE_ID STRING,
EMPLOYEE_NAME STRING,
DEPARTMENT STRING,
DESIGNATION STRING,
SALARY INTEGER,
JOINING_DATE DATE,
CITY STRING,
STATE STRING,
COUNTRY STRING,
INSERT_DTS TIMESTAMP(6),
UPDATE_DTS TIMESTAMP(6)
);

--Create the Stored procedure to execute the list of SQL queries to perform SCD1
CREATE OR REPLACE PROCEDURE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_SP()
RETURNS VARCHAR
LANGUAGE JAVASCRIPT
EXECUTE AS CALLER
AS
$$
try
{

//Create a temporary table store the flatten data from the stream
snowflake.execute({sqlText:`CREATE OR REPLACE TEMPORARY TABLE DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_TEMP AS
SELECT
JSON_DATA:employee_id::STRING AS EMPLOYEE_ID,
JSON_DATA:employee_name::STRING AS EMPLOYEE_NAME,
JSON_DATA:department::STRING AS DEPARTMENT,
JSON_DATA:designation::STRING AS DESIGNATION,
JSON_DATA:salary::INTEGER AS SALARY,
JSON_DATA:joining_date::DATE AS JOINING_DATE,
JSON_DATA:city::STRING AS CITY,
JSON_DATA:state::STRING AS STATE,
JSON_DATA:country::STRING AS COUNTRY
FROM DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_STREAM;`});

//Perform the SCD1 logic into the transformed table
snowflake.execute({sqlText:`MERGE INTO DEA_REAL_TIME_SCD1.TRANSFORMED.EMPLOYEE_TRANSFORMED T
USING DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_TEMP S
ON T.EMPLOYEE_ID = S.EMPLOYEE_ID

WHEN MATCHED THEN
UPDATE SET
    T.EMPLOYEE_NAME = S.EMPLOYEE_NAME,
    T.DEPARTMENT = S.DEPARTMENT,
    T.DESIGNATION = S.DESIGNATION,
    T.SALARY = S.SALARY,
    T.JOINING_DATE = S.JOINING_DATE,
    T.CITY = S.CITY,
    T.STATE = S.STATE,
    T.COUNTRY = S.COUNTRY,
    T.UPDATE_DTS = CURRENT_TIMESTAMP()

WHEN NOT MATCHED THEN
INSERT (
    EMPLOYEE_ID,
    EMPLOYEE_NAME,
    DEPARTMENT,
    DESIGNATION,
    SALARY,
    JOINING_DATE,
    CITY,
    STATE,
    COUNTRY,
    INSERT_DTS,
    UPDATE_DTS
)
VALUES (
    S.EMPLOYEE_ID,
    S.EMPLOYEE_NAME,
    S.DEPARTMENT,
    S.DESIGNATION,
    S.SALARY,
    S.JOINING_DATE,
    S.CITY,
    S.STATE,
    S.COUNTRY,
    CURRENT_TIMESTAMP(),
    CURRENT_TIMESTAMP());`});


//Statement returned for info and debuging purposes
return "Store Procedure Executed Successfully";

}

catch (err)
{
    result = 'Error: ' + err;
    snowflake.execute({sqlText:`ROLLBACK;`});
    throw result;
}
$$;

--Create the snowflake TASK to run the above stored procedure
CREATE OR REPLACE TASK DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_TASK
WAREHOUSE = COMPUTE_WH
SCHEDULE = '1 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_STREAM')
AS
CALL DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_SP();

--Show TASKS
SHOW TASKS;

--Alter the TASK to Resume/Suspend
ALTER TASK DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_TASK RESUME;
-- ALTER TASK DEA_REAL_TIME_SCD1.RAW.EMPLOYEE_SCD1_TASK SUSPEND;

--Check the status of the TASK
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.TASK_HISTORY(
        TASK_NAME => 'EMPLOYEE_SCD1_TASK'
    )
)
ORDER BY SCHEDULED_TIME DESC;

-- NOTE ON SCD1 CORRECTNESS: this MERGE has no tiebreaker for the case
-- where the SAME employee_id appears more than once in one stream batch
-- (e.g. two updates to E003 land within the same 1-minute task run) -
-- Snowflake's MERGE will error ("multiple rows matched") if that happens,
-- since WHEN MATCHED UPDATE can't apply two different updates to the same
-- target row in one statement. For this course's test pacing (one Postman
-- request, wait ~1 minute, send the next) you won't hit it - but it's
-- worth understanding as a real limitation of this exact design if you
-- ever fire rapid duplicate updates for the same employee_id.
