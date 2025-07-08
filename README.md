## Description

Example of several web applications containerized and deployed to AWS

Here is one of them, as an example: [team_1/subteam_1/app-1](team_1/subteam_1/app-1)

Each application is defined by the following things:

* `Dockerfile` (mandatory)
* `meta.yaml` file (mandatory)
* Application code and/or supporting files, used by `Dockerfile` (optional)

`meta.yaml` is a YAML file that defines the infrastructure resources required to build/deploy the application.

Each `meta.yaml` file has a single top-level key called `provision:`

`provision:` contains a list, and each entry in this list consists of a map with the following keys:

* `type:` defines the type of AWS resource (mandatory)
  * e.g `s3_bucket`, `iam_role`
* `name:` defines the unique name of the AWS resource (mandatory)
  * e.g the name of the bucket in case of `s3_bucket`
* Any other keys defined by the provision of a specific `type:` (optional or mandatory)
  * e.g `image:` is mandatory for `type: app_runner` but does not exist for other `type:`

On `meta.yaml` parsing, the name of the application must be substituted into each `{name}` inside the `meta.yaml` file.

The goal of this test task is to produce a GitLab CI pipeline, that finds all applications across the entire repository (any dir, any level) and:

* Builds the related Dockerfile
* Provisions the `ecr_registry` from the `provision:` section of `meta.yaml`
* Pushes the built image into the provisioned `ecr_registry`
* Provisions the rest of the `provision:` section

GitLab CI pipeline must pass as green on top of clean AWS account state (no provisioned resources), and addition of new apps should no require any changes to CI/scripts.

Result of the pipeline is that all repository applications are running in [AWS AppRunner](https://aws.amazon.com/apprunner/) with a green health check.

Bonus points: Each application is processed in a parallel GitLab CI job.

## Pre-defined environment variables

[GitLab CI Variables](https://gitlab.com/nikita.savitsky1/behavox-platform-sre-test-task-561d34da/-/settings/ci_cd#js-cicd-variables-settings) for this repository

* `AWS_ACCOUNT_ID`: ID of the AWS account
* `AWS_DEFAULT_REGION`: Region to be used for infrastructure provision
* `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`: API Key with Admin access to the AWS account
* `AWS_WEB_UI_USER_NAME` and `AWS_WEB_UI_USER_PASS`: Credentials to access AWS Web UI, not expected to be used by CI

## To improve

1. Using meta.yml instead hardcoded the IAM configuration in terraform/modules/app
2. Incorrect parsing of meta.yml — cpu, port, memory are assumed to be at the root, hence values in provisioning are ignored, and defaults defined in from parse_meta() are used instead
3. GitLab matrix job build_apps generated into .gitlab-ci-build-matrix.yml is not referenced
4. On first execution, if there was no TF state S3 bucket and DynamoDB table, TF will try to create them, but job ignores any errors (including errors not related to prior S3 bucket/dynamodb table existence
5. Dynamodb table is a deprecate TF feature
6. No parallelism inside of gitlab jobs, or on gitlab job(s) level
7. Passed -var="aws_account_id=$AWS_ACCOUNT_ID" etc. to Terraform but never used them
8. No Docker/Python linters used (adding them would be a plus)
