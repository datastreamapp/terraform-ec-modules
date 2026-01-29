variable "name" {
  type = string
}
variable "description" {
  type    = string
  default = null
}

variable "edge" {
  description = "flag if it is a Lambda@Edge"
  type        = bool
  default     = false
}

variable "package_type" {
  type    = string
  default = "Zip" # Image
}

variable "source_file" {
  description = "Set to file name within source_dir to only use one file"
  type        = string
  default     = ""
}

variable "source_dir" {
  description = "Must not end with trailing /"
  type        = string
}

variable "image_uri" {
  description = "Set to ECR container image uri"
  type        = string
  default     = ""
}

variable "excludes" {
  type    = list(string)
  default = []
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "layers" {
  type    = list(string)
  default = null
}
variable "runtime" {
  type    = string
  default = "nodejs22.x"
}
variable "architecture" {
  type    = string
  default = "arm64"
}
variable "timeout" {
  type        = string
  default     = "5" # CloudFront=5, API Gateway=29, Max=900
  description = "in seconds"
}
variable "memory" {
  type        = string
  default     = "128"
  description = "1024 = 1 GB"
}

variable "provisioned_concurrecy" {
  type    = number
  default = 0
}

variable "reserved_concurrency" {
  type    = number
  default = -1
}

# Logs
variable "retention_in_days" {
  type    = number
  default = 0 # [CloudWatch.16] This controls evaluates if a CloudWatch log group has a retention period of at least 1 year.
}
variable "kms_key_arn" {
  type    = string
  default = null
}

# Cloudwatch
variable "enable_cloudwatch_dashboard" {
  type    = bool
  default = false
}

variable "log_severity_property_name" {
  type        = string
  description = "Property name for severity in error logs"
  default     = "log_level"
}

variable "log_http_status_code_property_name" {
  type        = string
  description = "Property name for status codes in error logs"
  default     = "status_code"
}

# VPC
variable "vpc_id" {
  type    = string
  default = ""
}
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "private_subnet_ids" {
  type    = list(string)
  default = []
}

variable "volumes" {
  type = list(object({
    arn = string
    local_mount_path = optional(string, "/mnt/efs")
  }))
  default = []
}

# CI
variable "s3_bucket" {
  type = string
  default = ""
}

variable "code_signing_config_arn" {
  description = ""
  type        = string
  default     = null
}

variable "signer_profile_name" {
  type = string
  default = null
}

# CI/CD Artifact Source (v4.2.0)
variable "artifact_source" {
  description = "Where Lambda artifacts come from: 'local' builds ZIP via archive_file (default), 'cicd' uses pre-built signed S3 artifact"
  type        = string
  default     = "local"

  validation {
    condition     = contains(["local", "cicd"], var.artifact_source)
    error_message = "artifact_source must be 'local' or 'cicd'."
  }
}

variable "artifact_s3_key" {
  description = "Pre-built signed S3 key for the Lambda artifact (required when artifact_source = 'cicd')"
  type        = string
  default     = null
}

variable "artifact_hash" {
  description = "Source code hash for change detection (required when artifact_source = 'cicd', maps to source_code_hash)"
  type        = string
  default     = null
}

# Lambda@Edge Doesn't support DQL
variable "dead_letter_arn" {
  description = "sns or sqs arn. need to apply sns:Publish or sqs:SendMessage to iam"
  type        = string
  default     = null
}

# Lambda@Edge Doesn't support extra process.env
variable "env" {
  type    = map(string)
  default = {}
}



