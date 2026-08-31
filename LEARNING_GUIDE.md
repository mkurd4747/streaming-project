# Learning Guide — module by module

Each section: the concept, the file(s) involved, and what "done" looks
like before moving to the next module. Mirrors the course's 14 modules.
Modules 5 and 7-9 are marked **(given)** — the course hands you that code
directly, so there's no separate exercise there beyond running it and
understanding it. Modules 2-4 and 6 are **(you build)** — the AWS Console
clicking the course teaches is what you're replacing with Terraform.

## 1. Project Overview
Read `README.md`'s architecture diagram until you can redraw it from
memory.

## 2. AWS S3 Buckets — (you build)
File: `terraform/modules/s3/main.tf`
Data bucket + error bucket, encryption, public-access blocks, lifecycle
rules. No bucket policy needed this time — see the file's header comment
for why.
**Done when:** `terraform validate` passes.

## 3. AWS IAM Roles — (you build)
File: `terraform/modules/iam/main.tf`
Two roles, matching what you built in the console: a shared role for API
Gateway/Lambda/Firehose (5 AWS-managed policies), and a Snowflake
storage-integration role (1 managed policy, plus the two-phase-apply
trust policy — read that part of the file's comments twice).
**Done when:** `terraform validate` passes.

## 4. AWS Kinesis Stream + Firehose — (you build)
Files: `terraform/modules/kinesis_stream/main.tf`,
`terraform/modules/firehose/main.tf`
One Kinesis Data Stream, one Firehose delivery stream reading from it and
writing to the S3 data bucket.
**Done when:** `terraform apply` (phase 1, root wired) creates both and
you can see them in the AWS console.

## 5. AWS Lambda — (given)
File: `lambda_src/handler.py` — this is the course's own code, already
filled in for you (adapted only to read `KINESIS_STREAM_NAME` /
`ERROR_BUCKET_NAME` from environment variables instead of hardcoded
strings, since Terraform sets those). Read through it: note the
validation is *just* "does `employee_id` exist and is it non-blank" —
nothing else. Note the fixed `PartitionKey='1'` on every `put_record` call
— every record goes to the same shard; fine for a learning project's
volume, but it means no key-based parallelism.
**What you still build:** `terraform/modules/lambda/main.tf` — the
Terraform that zips and deploys this file.
**Done when:** `terraform apply` succeeds and you can manually invoke the
function in the console with a test event.

## 6. AWS API Gateway — (you build)
File: `terraform/modules/api_gateway/main.tf`, plus the
`aws_lambda_permission` resource in root `terraform/main.tf`.
**Done when:** `terraform output api_invoke_url` gives a real URL, and a
POST to it gets a response from Lambda (even a validation error proves
the chain works).

## 7. AWS ⇄ Snowflake Integration — (given)
Files: `snowflake_sql/01_setup.sql`, `02_storage_integration.sql`,
`03_stage_and_file_format.sql`
Run 01 as-is. For 02: phase 1 uses the placeholder-trusting IAM role ARN
(`terraform output snowflake_integration_role_arn`) → run `DESC
INTEGRATION` → phase 2 `terraform apply` with the real values. Then 03.
**Done when:** `LIST @DEA_REAL_TIME_SCD1_STAGE;` doesn't error.

## 8. Snowflake Snowpipe — (given)
File: `snowflake_sql/04_raw_table_and_snowpipe.sql`
Creates `EMPLOYEE_RAW` and `EMPLOYEE_PIPE`. `DESC PIPE` gives the SQS ARN
→ phase-2 `terraform apply` again to wire the S3 event notification.
**Done when:** POSTing test data results in rows appearing in
`EMPLOYEE_RAW` within about a minute, with no manual `ALTER PIPE ...
REFRESH`.

## 9. Snowflake Stream & Task — (given)
File: `snowflake_sql/05_stream_and_scd1_task.sql`
`EMPLOYEE_STREAM` (append-only CDC on `EMPLOYEE_RAW`), a stored procedure
(`EMPLOYEE_SCD1_SP`) that flattens the stream into a temp table and MERGEs
it into `EMPLOYEE_TRANSFORMED`, and a task (`EMPLOYEE_SCD1_TASK`) that
calls the procedure once a minute when the stream has data. Read the note
at the bottom of the file about what happens if the same `employee_id`
appears twice in one batch.
**Done when:** rows in `EMPLOYEE_RAW` show up (overwritten in place on
repeat `employee_id`s) in `EMPLOYEE_TRANSFORMED` within about a minute.

## 10. Postman Setup
Files: `postman/streaming-pipeline.postman_collection.json`,
`sample_payloads/*.json`. You're using web.postman.com — import the
collection, set `api_url` to your real invoke URL, paste each sample
payload into the matching request body.

## 11. Test the Pipeline with Full Data
Run `snowflake_sql/06_check_before_test.sql` first. Send
`01_full_load.json` (10 employees). Trace it through: Lambda response →
CloudWatch logs → S3 data bucket (`raw/...`) → `EMPLOYEE_RAW` →
`EMPLOYEE_TRANSFORMED`. All 10 should appear.

## 12. Test the Pipeline with Incremental Data
Send `02_incremental_update.json`. E003, E005, and E008 (already exist)
get **updated in place** — new designation/salary/city, no duplicate
rows. E011 and E012 get **inserted** as new hires.

## 13. Test the Pipeline with Invalid Data
Send `03_invalid_data.json` — a realistic mix: E007 updated, E013/E014/
E015 as new hires, and two records with a blank `employee_id`. Confirm
the Lambda response shows 4 successes / 2 errors, the two blank-id
records land in the S3 error bucket, and only the 4 valid ones show up in
`EMPLOYEE_TRANSFORMED`.

## 14. Delete the Project Setup
Run `snowflake_sql/08_teardown.sql`, then `terraform destroy`. Confirm in
both the Snowflake UI and AWS console that everything is actually gone —
don't leave a Kinesis Data Stream or a Snowflake trial warehouse running
after you're done, both cost/consume credits continuously.
