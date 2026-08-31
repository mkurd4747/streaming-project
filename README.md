# End-to-End Real-Time Streaming with SCD1 — AWS + Snowflake (Terraform)

A learning scaffold for the Data Engineer Academy course of the same name.
**You write the AWS Terraform yourself.** The course hands you the
Snowflake SQL and the Lambda application code directly (that's how the
course teaches it) — those live under `snowflake_sql/` and
`lambda_src/handler.py` as working, ready-to-run code, transcribed from
the course's own materials. The actual learning exercise is everything
under `terraform/modules/*/main.tf`: translating the AWS resources the
course has you click together by hand in the Console into Terraform
instead. Every one of those files is a TODO skeleton with a concept
explanation — not a finished solution. A complete working version of the
whole thing lives under `reference/`, so you always have something to
check against once you've had a real attempt.

Architecture:

```
Postman (web.postman.com)
      |
      v
API Gateway --> Lambda --+--> (valid)   Kinesis Data Stream --> Kinesis Firehose --> S3 Data Bucket
                          |                                                                |
                          +--> (invalid) S3 Error Bucket                                   v
                                                                                  S3 event --> SQS --> Snowpipe
                                                                                                          |
                                                                                                          v
                                                                                    EMPLOYEE_RAW (Snowflake, RAW schema)
                                                                                                          |
                                                                              EMPLOYEE_STREAM + EMPLOYEE_SCD1_TASK
                                                                                (calls a stored procedure that MERGEs)
                                                                                                          |
                                                                                                          v
                                                                                EMPLOYEE_TRANSFORMED (TRANSFORMED schema)
```

Entity: **employee** records (`employee_id`, `employee_name`, `department`,
`designation`, `salary`, `joining_date`, `city`, `state`, `country`).
Validation rule (from the course's Lambda code): a record is invalid if
`employee_id` is missing or blank — that's the *only* check, nothing else
is validated. Region: `us-east-1`. Database: `DEA_REAL_TIME_SCD1`, using
the trial account's built-in `COMPUTE_WH` warehouse (no need to create a
new one).

## Repo layout

```
terraform/            <- YOU write the resource logic here (TODO skeletons)
  versions.tf          given: provider/version pins
  variables.tf          given: input variables, including the phase-2 placeholders
  terraform.tfvars.example
  main.tf               TODO: wire the 6 modules together
  outputs.tf            TODO: expose useful values
  modules/
    s3/                 TODO main.tf   (given: variables.tf, outputs.tf)
    iam/                TODO main.tf   - 2 roles, AWS managed policies (matches what you built in the console)
    kinesis_stream/     TODO main.tf
    firehose/           TODO main.tf
    lambda/             TODO main.tf
    api_gateway/        TODO main.tf

lambda_src/handler.py  <- given: the course's own Lambda code (env-var adapted)

snowflake_sql/         <- given: the course's own SQL, numbered in module order:
  01_setup.sql                     module 7 - database/schemas
  02_storage_integration.sql       module 7 - AWS<->Snowflake trust (phase 1)
  03_stage_and_file_format.sql     module 7 - external stage
  04_raw_table_and_snowpipe.sql    module 8 - EMPLOYEE_RAW + EMPLOYEE_PIPE
  05_stream_and_scd1_task.sql      module 9 - EMPLOYEE_STREAM + stored-proc SCD1 MERGE + EMPLOYEE_SCD1_TASK
  06_check_before_test.sql         module 11 - sanity-check queries before/after sending test data
  07_pause_pipeline.sql            pause Snowpipe + suspend the task between test sessions (no data loss)
  08_teardown.sql                  module 14 - full drop (not from the course verbatim, follows the same names)

sample_payloads/       <- given: the course's own test JSON (10 employees full load,
                          incremental updates + 2 new hires, incremental+invalid mix)
postman/               <- given: Postman collection shell (paste payloads in)

reference/             <- ANSWER KEY for the Terraform side only. Same
                          structure, fully working. Don't open it until
                          you've had a real attempt at the corresponding
                          file — that's where the learning is.
```

Two things you already built in the AWS Console that are worth knowing
about before you write the Terraform:
- **IAM role 1** (`dea-real-time-scd1-aws-role`): trusted by
  `apigateway.amazonaws.com`, `lambda.amazonaws.com`, and
  `firehose.amazonaws.com`, with AWS *managed* full-access policies
  attached (`AWSLambda_FullAccess`, `AmazonKinesisFullAccess`,
  `AmazonKinesisFirehoseFullAccess`, `AmazonS3FullAccess`,
  `CloudWatchFullAccess`) — one shared role, not three separate ones.
- **IAM role 2** (`dea-real-time-scd1-snowflake-role`): trusted by
  Snowflake's own AWS identity (with an external-ID condition), with
  `AmazonS3FullAccess` attached.

That's simpler than a "real" least-privilege setup would be (full-access
managed policies are broad), but it's what the course teaches and it's
what `terraform/modules/iam/main.tf`'s TODO comments now describe — build
to that.

## Prerequisites (do these once)

### 1. AWS account + CLI
- AWS account with billing enabled.
- Install AWS CLI v2. On Windows: `winget install Amazon.AWSCLI`.
- Create an IAM access key (IAM → Users → your user → Security
  credentials → Create access key → "Command Line Interface (CLI)").
- `aws configure` — region `us-east-1`, output format `json`.
- Verify: `aws sts get-caller-identity`.

### 2. Terraform
- Install Terraform >= 1.5. On Windows: `winget install Hashicorp.Terraform`.
- No separate login needed — it reads credentials from the AWS CLI config.

### 3. Snowflake trial account
- Sign up for a free trial, AWS as the cloud provider, a region close to
  (ideally the same as) `us-east-1`.
- Open a SQL worksheet — that's where you run everything under
  `snowflake_sql/`, in numeric order.

### 4. Postman
- You're using the web app at web.postman.com — that's fine, no local
  install needed. Since API Gateway gives you a public HTTPS URL, there's
  no localhost/tunneling concern like there would be with a locally-run
  API.
- Import `postman/streaming-pipeline.postman_collection.json` when you get
  to module 10.

## Workflow — two-phase Terraform apply

Snowflake needs an AWS IAM role ARN to create its storage integration, but
that role's trust policy needs values Snowflake only generates *after*
the integration exists. Fix: apply Terraform twice.

1. **Phase 1**: `terraform apply` with the placeholder values in
   `variables.tf` / `terraform.tfvars`. Stands up all of AWS: S3, IAM (2
   roles), Kinesis Stream, Firehose, Lambda, API Gateway.
2. Run `snowflake_sql/02_storage_integration.sql`'s `DESC INTEGRATION`
   and `snowflake_sql/04_raw_table_and_snowpipe.sql`'s `DESC PIPE` — copy
   the real values into `terraform.tfvars`.
3. **Phase 2**: `terraform apply` again. Only the IAM trust policy and
   the S3 event notification change — nothing is destroyed.

Full step order, matching the course's 14 modules, is in
[`LEARNING_GUIDE.md`](LEARNING_GUIDE.md).

## Testing (course modules 11-13)

Run `snowflake_sql/06_check_before_test.sql` first (and whenever you want
to check pipeline state). Then, from Postman:
1. POST `sample_payloads/01_full_load.json` (10 employees) — check rows
   land in `EMPLOYEE_RAW` and then `EMPLOYEE_TRANSFORMED`.
2. POST `sample_payloads/02_incremental_update.json` — E003/E005/E008
   should be **overwritten in place** (SCD1), E011/E012 **inserted** as
   new.
3. POST `sample_payloads/03_invalid_data.json` (a mix: one real update,
   three new hires, and two records with a blank `employee_id`) — confirm
   the two blank-id records land in the S3 error bucket and never reach
   Snowflake, while the other four flow through normally.

## Pausing / Teardown

- Between test sessions: `snowflake_sql/07_pause_pipeline.sql` pauses
  Snowpipe and suspends the task without dropping anything.
- Full teardown (course module 14): `snowflake_sql/08_teardown.sql` first,
  then `terraform destroy` from `terraform/`.

## When you're stuck

Try in this order: re-read the concept comment in the TODO file →
check the relevant AWS provider docs for the resource type mentioned →
ask a specific question ("why does my IAM trust policy reject Snowflake's
assume-role call?") → compare against `reference/`.
