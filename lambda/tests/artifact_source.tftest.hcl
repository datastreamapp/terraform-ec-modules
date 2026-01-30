mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-role"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }
  mock_resource "aws_signer_signing_job" {
    defaults = {
      signed_object = [{
        s3 = [{
          bucket = "test-bucket"
          key    = "signed/test-lambda-local.zip"
        }]
      }]
    }
  }
}
mock_provider "archive" {}

variables {
  name                = "test-lambda"
  source_dir          = "./tests/fixtures"
  source_file         = "index.mjs"
  s3_bucket           = "test-bucket"
  signer_profile_name = "test-profile"
  kms_key_arn         = "arn:aws:kms:ca-central-1:123456789012:key/test-key-id"
  dead_letter_arn     = "arn:aws:sns:ca-central-1:123456789012:test-dlq"
}

# --- Test 1: Local mode creates archive, S3 object, and signing job ---

run "local_mode_creates_archive_file" {
  command = plan

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = length(data.archive_file.lambda_file) == 1
    error_message = "archive_file.lambda_file should be created in local mode"
  }

  assert {
    condition     = length(data.archive_file.lambda_dir) == 0
    error_message = "archive_file.lambda_dir should be skipped when source_file is set"
  }
}

run "local_mode_creates_s3_object" {
  command = plan

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = length(aws_s3_object.lambda) == 1
    error_message = "aws_s3_object should be created in local mode"
  }
}

run "local_mode_creates_signing_job" {
  command = plan

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = length(aws_signer_signing_job.lambda) == 1
    error_message = "aws_signer_signing_job should be created in local mode"
  }
}

run "local_mode_s3_key_from_signing_job" {
  command = apply

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = aws_lambda_function.lambda.s3_key == "signed/test-lambda-local.zip"
    error_message = "s3_key should read from signing job output in local mode"
  }
}

# --- Test 2: CICD mode skips archive, S3 object, and signing job ---

run "cicd_mode_skips_archive_file" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-lambda-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(data.archive_file.lambda_file) == 0
    error_message = "archive_file.lambda_file should be skipped in cicd mode"
  }

  assert {
    condition     = length(data.archive_file.lambda_dir) == 0
    error_message = "archive_file.lambda_dir should be skipped in cicd mode"
  }
}

run "cicd_mode_skips_s3_object" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-lambda-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(aws_s3_object.lambda) == 0
    error_message = "aws_s3_object should be skipped in cicd mode"
  }
}

run "cicd_mode_skips_signing_job" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-lambda-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(aws_signer_signing_job.lambda) == 0
    error_message = "aws_signer_signing_job should be skipped in cicd mode"
  }
}

# --- Test 3: s3_key reads from correct source ---

run "cicd_mode_s3_key_from_variable" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-lambda-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = aws_lambda_function.lambda.s3_key == "signed/test-lambda-abc123.zip"
    error_message = "s3_key should read from artifact_s3_key in cicd mode"
  }
}

# --- Test 4: source_code_hash set only in cicd + Zip mode ---

run "cicd_mode_sets_source_code_hash" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-lambda-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = aws_lambda_function.lambda.source_code_hash == "abc123hash"
    error_message = "source_code_hash should equal artifact_hash in cicd mode"
  }
}

run "image_mode_skips_all_zip_resources" {
  command = plan

  variables {
    package_type    = "Image"
    image_uri       = "123456789.dkr.ecr.ca-central-1.amazonaws.com/test:latest"
    artifact_source = "cicd"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(data.archive_file.lambda_file) == 0
    error_message = "archive_file should be skipped for Image package type"
  }

  assert {
    condition     = length(aws_s3_object.lambda) == 0
    error_message = "aws_s3_object should be skipped for Image package type"
  }

  assert {
    condition     = length(aws_signer_signing_job.lambda) == 0
    error_message = "aws_signer_signing_job should be skipped for Image package type"
  }
}

# --- Negative: local mode must NOT set source_code_hash ---

run "local_mode_no_source_code_hash" {
  command = plan

  variables {
    artifact_source = "local"
    artifact_hash   = "should-not-appear"
  }

  assert {
    condition     = aws_lambda_function.lambda.source_code_hash != "should-not-appear"
    error_message = "source_code_hash must not use artifact_hash in local mode"
  }
}

# --- Test 5: Validation rejects invalid artifact_source ---

run "invalid_artifact_source_rejected" {
  command = plan

  variables {
    artifact_source = "invalid"
  }

  expect_failures = [
    var.artifact_source,
  ]
}
