data "archive_file" "layer" {
  count       = var.artifact_source == "local" ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  excludes    = var.excludes
  output_path = "/tmp/${var.name}.zip"
}

resource "aws_s3_object" "layer" {
  count                  = var.artifact_source == "local" ? 1 : 0
  bucket                 = var.s3_bucket
  key                    = "unsigned/${var.name}-${data.archive_file.layer[0].output_md5}.zip"
  source                 = data.archive_file.layer[0].output_path
  checksum_algorithm     = "SHA256"
  force_destroy          = true # For Object Lock
  depends_on             = [data.archive_file.layer]
}

resource "aws_signer_signing_job" "layer" {
  count        = var.artifact_source == "local" ? 1 : 0
  profile_name = var.signer_profile_name

  source {
    s3 {
      bucket  = var.s3_bucket
      key     = aws_s3_object.layer[0].id
      version = aws_s3_object.layer[0].version_id
    }
  }

  destination {
    s3 {
      bucket = var.s3_bucket
      prefix = "signed/${var.name}-"
    }
  }

  ignore_signing_job_failure = false
  depends_on = [
    aws_s3_object.layer
  ]
}

resource "aws_lambda_layer_version" "layer" {
  layer_name   = var.name
  description  = var.description
  license_info = var.license_info
  s3_bucket    = var.s3_bucket
  s3_key       = var.artifact_source == "cicd" ? var.artifact_s3_key : aws_signer_signing_job.layer[0].signed_object[0]["s3"][0]["key"]

  source_code_hash = var.artifact_source == "cicd" ? var.artifact_hash : null

  #compatible_architectures = var.compatible_architectures # CompatibleArchitectures are not supported in ca-central-1. Please remove the CompatibleArchitectures value from your request and try again
  compatible_runtimes = var.compatible_runtimes

  lifecycle {
    precondition {
      condition     = var.artifact_source != "cicd" || var.artifact_s3_key != null
      error_message = "artifact_s3_key is required when artifact_source = 'cicd'."
    }
    precondition {
      condition     = var.artifact_source != "cicd" || var.artifact_hash != null
      error_message = "artifact_hash is required when artifact_source = 'cicd'."
    }
  }
}

resource "aws_lambda_layer_version_permission" "layer" {
  statement_id   = "account-only"
  layer_name     = aws_lambda_layer_version.layer.layer_arn
  version_number = aws_lambda_layer_version.layer.version
  principal      = local.account_id
  action         = "lambda:GetLayerVersion"
}
