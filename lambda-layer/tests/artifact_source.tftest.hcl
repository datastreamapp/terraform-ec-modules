mock_provider "aws" {
  mock_resource "aws_signer_signing_job" {
    defaults = {
      signed_object = [{
        s3 = [{
          bucket = "test-bucket"
          key    = "signed/test-layer-local.zip"
        }]
      }]
    }
  }
  mock_resource "aws_lambda_layer_version" {
    defaults = {
      version = 1
    }
  }
}
mock_provider "archive" {}

variables {
  name                = "test-layer"
  source_dir          = "./tests/fixtures"
  s3_bucket           = "test-bucket"
  signer_profile_name = "test-profile"
  code_signing_config_arn = "arn:aws:lambda:ca-central-1:123456789012:code-signing-config/csc-test"
}

# --- Local mode: creates archive, S3 object, and signing job ---

run "local_mode_creates_archive_file" {
  command = plan

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = length(data.archive_file.layer) == 1
    error_message = "archive_file.layer should be created in local mode"
  }
}

run "local_mode_creates_s3_object" {
  command = plan

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = length(aws_s3_object.layer) == 1
    error_message = "aws_s3_object should be created in local mode"
  }
}

run "local_mode_creates_signing_job" {
  command = plan

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = length(aws_signer_signing_job.layer) == 1
    error_message = "aws_signer_signing_job should be created in local mode"
  }
}

run "local_mode_s3_key_from_signing_job" {
  command = apply

  variables {
    artifact_source = "local"
  }

  assert {
    condition     = aws_lambda_layer_version.layer.s3_key == "signed/test-layer-local.zip"
    error_message = "s3_key should read from signing job output in local mode"
  }
}

# --- CICD mode: skips archive, S3 object, and signing job ---

run "cicd_mode_skips_archive_file" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-layer-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(data.archive_file.layer) == 0
    error_message = "archive_file.layer should be skipped in cicd mode"
  }
}

run "cicd_mode_skips_s3_object" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-layer-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(aws_s3_object.layer) == 0
    error_message = "aws_s3_object should be skipped in cicd mode"
  }
}

run "cicd_mode_skips_signing_job" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-layer-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = length(aws_signer_signing_job.layer) == 0
    error_message = "aws_signer_signing_job should be skipped in cicd mode"
  }
}

run "cicd_mode_s3_key_from_variable" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-layer-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = aws_lambda_layer_version.layer.s3_key == "signed/test-layer-abc123.zip"
    error_message = "s3_key should read from artifact_s3_key in cicd mode"
  }
}

run "cicd_mode_sets_source_code_hash" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-layer-abc123.zip"
    artifact_hash   = "abc123hash"
  }

  assert {
    condition     = aws_lambda_layer_version.layer.source_code_hash == "abc123hash"
    error_message = "source_code_hash should equal artifact_hash in cicd mode"
  }
}

# --- Negative: local mode must NOT set source_code_hash ---

run "local_mode_no_source_code_hash" {
  command = plan

  variables {
    artifact_source = "local"
    artifact_hash   = "should-not-appear"
  }

  # Mock providers assign synthetic values to string attributes even when the
  # expression evaluates to null, so we cannot assert == null here. Instead,
  # verify the artifact_hash variable value is not passed through.
  assert {
    condition     = aws_lambda_layer_version.layer.source_code_hash != "should-not-appear"
    error_message = "source_code_hash must not use artifact_hash in local mode"
  }
}

# --- Precondition rejects cicd mode without required variables ---

run "cicd_mode_rejects_missing_artifact_s3_key" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_hash   = "abc123hash"
  }

  expect_failures = [
    aws_lambda_layer_version.layer,
  ]
}

run "cicd_mode_rejects_missing_artifact_hash" {
  command = plan

  variables {
    artifact_source = "cicd"
    artifact_s3_key = "signed/test-layer-abc123.zip"
  }

  expect_failures = [
    aws_lambda_layer_version.layer,
  ]
}

# --- Validation ---

run "invalid_artifact_source_rejected" {
  command = plan

  variables {
    artifact_source = "invalid"
  }

  expect_failures = [
    var.artifact_source,
  ]
}
