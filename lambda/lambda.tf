data "archive_file" "lambda_file" {
  count       = var.package_type == "Zip" && var.source_file != "" && var.artifact_source == "local" ? 1 : 0
  type        = "zip"
  source_file = "${var.source_dir}/${var.source_file}"
  output_path = "/tmp/${var.name}.zip"
}

data "archive_file" "lambda_dir" {
  count       = var.package_type == "Zip" && var.source_file == "" && var.artifact_source == "local" ? 1 : 0
  type        = "zip"
  source_dir  = var.source_dir
  excludes    = var.excludes
  output_path = "/tmp/${var.name}.zip"
}

resource "aws_s3_object" "lambda" {
  count                  = var.package_type == "Zip" && var.s3_bucket != "" && var.artifact_source == "local" ? 1 : 0
  bucket                 = var.s3_bucket
  key                    = "unsigned/${var.name}-${var.source_file != "" ? data.archive_file.lambda_file[0].output_md5 : data.archive_file.lambda_dir[0].output_md5}.zip"
  source                 = var.source_file != "" ? data.archive_file.lambda_file[0].output_path : data.archive_file.lambda_dir[0].output_path
  checksum_algorithm     = "SHA256"
  force_destroy          = true # For Object Lock in Governance Mode
  depends_on             = [
    data.archive_file.lambda_file, data.archive_file.lambda_dir
  ]
}

resource "aws_signer_signing_job" "lambda" {
  count        = var.package_type == "Zip" && var.artifact_source == "local" ? 1 : 0
  profile_name = var.signer_profile_name

  source {
    s3 {
      bucket  = var.s3_bucket
      key     = aws_s3_object.lambda[0].id
      version = aws_s3_object.lambda[0].version_id
    }
  }

  destination {
    s3 {
      bucket = var.s3_bucket
      prefix = "signed/${var.name}-"
    }
  }

  ignore_signing_job_failure = false
  depends_on                 = [
    aws_s3_object.lambda
  ]
}

locals {
  image_uri               = var.package_type == "Image" ? var.image_uri : null
  s3_bucket               = var.package_type == "Zip" ? var.s3_bucket : null
  s3_key                  = var.package_type == "Zip" ? (var.artifact_source == "cicd" ? var.artifact_s3_key : aws_signer_signing_job.lambda[0].signed_object[0]["s3"][0]["key"]) : null
  handler                 = var.package_type == "Zip" ? var.handler : null
  layers                  = var.package_type == "Zip" ? var.layers : null
  runtime                 = var.package_type == "Zip" ? var.runtime : null
  architectures           = var.package_type == "Zip" ? [lower(var.architecture)] : null
  code_signing_config_arn = var.package_type == "Zip" ? var.code_signing_config_arn : null
}

resource "aws_lambda_function" "lambda" {
  depends_on = [
    aws_signer_signing_job.lambda
  ]
  function_name                  = var.name
  description                    = local.description
  role                           = aws_iam_role.lambda.arn
  package_type                   = var.package_type
  image_uri                      = local.image_uri
  s3_bucket                      = local.s3_bucket
  s3_key                         = local.s3_key
  source_code_hash               = var.artifact_source == "cicd" && var.package_type == "Zip" ? var.artifact_hash : null
  code_signing_config_arn        = local.code_signing_config_arn
  handler                        = local.handler
  layers                         = local.layers
  runtime                        = local.runtime
  architectures                  = local.architectures
  memory_size                    = var.memory
  reserved_concurrent_executions = var.reserved_concurrency
  timeout                        = var.timeout
  publish                        = true

  dynamic "dead_letter_config" {
    for_each = var.edge ? [] : [
      1
    ]
    content {
      target_arn = try(module.lambda-dlq[0].arn, var.dead_letter_arn)
    }
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = var.security_group_ids
  }
  
  dynamic "file_system_config" {
    for_each = var.volumes
    content {
      arn = file_system_config.value["arn"]
      local_mount_path = file_system_config.value["local_mount_path"]
    }
  }

  dynamic "environment" {
    for_each = var.edge ? [] : [
      1
    ]
    content {
      variables = local.env
    }
  }

  lifecycle {
    precondition {
      condition     = var.artifact_source != "cicd" || var.artifact_s3_key != null
      error_message = "artifact_s3_key is required when artifact_source = 'cicd'."
    }
    precondition {
      condition     = var.artifact_source != "cicd" || var.package_type != "Zip" || var.artifact_hash != null
      error_message = "artifact_hash is required when artifact_source = 'cicd' and package_type = 'Zip'."
    }
    ignore_changes = [
      code_signing_config_arn
    ]
  }
}


//resource "aws_lambda_alias" "lambda" {
//  name             = "latest"
//  description      = "points to the latest version"
//  function_name    = aws_lambda_function.lambda.function_name
//  function_version = aws_lambda_function.lambda.version
//}

//resource "aws_lambda_provisioned_concurrency_config" "lambda" {
//  count                             = (var.provisioned_concurrecy == 0) ? 0 : 1
//  function_name                     = aws_lambda_function.lambda.function_name
//  provisioned_concurrent_executions = var.provisioned_concurrecy
//  qualifier                         = aws_lambda_alias.lambda.name
//}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.edge ? "us-east-1." : ""}${var.name}"
  retention_in_days = var.retention_in_days == 0 ? (terraform.workspace == "production" ? 365 : 7) : var.retention_in_days
  kms_key_id        = var.kms_key_arn
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda-role"
  assume_role_policy = var.edge ? data.aws_iam_policy_document.edge-lambda.json : data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }

  }
}

data "aws_iam_policy_document" "edge-lambda" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com",
      ]
    }

  }
}

/*
condition {
  test     = "StringEquals"
  values   = [local.account_id]
  variable = "AWS:SourceAccount"
}
*/

# Adds CloudWatch
resource "aws_iam_role_policy_attachment" "cloud-watch" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add X-Ray
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

# Add NetworkInterface
resource "aws_iam_role_policy_attachment" "vpc" {
  count      = length(var.private_subnet_ids) == 0 ? 0 : 1
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

# Add ECR
resource "aws_iam_policy" "ecr" {
  count  = var.package_type == "Image" ? 1 : 0
  name   = "${var.name}ECRAccess"
  policy = data.aws_iam_policy_document.ecr.json
}

data "aws_iam_policy_document" "ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetRepositoryPolicy",
      # "ecr:SetRepositoryPolicy",
      "ecr:LambdaECRImageRetrievalPolicy",
    ]
    resources = ["*"]
  }

}
resource "aws_iam_role_policy_attachment" "ecr" {
  count      = var.package_type == "Image" ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.ecr.0.arn
}