variable "name" {
  type = string
}
variable "description" {
  type = string
  default = null
}

variable "source_dir" {
  description = "Only supports `source_dir` with `nodejs/node_modules/*` inside"
  type = string
}

variable "excludes" {
  type = list(string)
  default = []
}

# CI
variable "s3_bucket" {
  type = string
}

variable "code_signing_config_arn" {
  description = ""
  type = string
}

variable "signer_profile_name" {
  type = string
}

# CI/CD Artifact Source (v4.2.0)
variable "artifact_source" {
  description = "Where Lambda layer artifacts come from: 'local' builds ZIP via archive_file (default), 'cicd' uses pre-built signed S3 artifact"
  type        = string
  default     = "local"
  validation {
    condition     = contains(["local", "cicd"], var.artifact_source)
    error_message = "artifact_source must be 'local' or 'cicd'."
  }
}

variable "artifact_s3_key" {
  description = "Pre-built signed S3 key for the Lambda layer artifact (required when artifact_source = 'cicd')"
  type        = string
  default     = null
}

variable "artifact_hash" {
  description = "Source code hash for change detection (required when artifact_source = 'cicd', maps to source_code_hash)"
  type        = string
  default     = null
}

# Layer
variable "license_info" {
  type = string
  default = null
}
variable "compatible_architectures" {
  type = list(string)
  default = ["x86_64","arm64"]
}
variable "compatible_runtimes" {
  type = list(string)
  default = ["nodejs","nodejs20.x","nodejs22.x"]
}

# Layer Perms
#variable "principal" {
#  type = string
#  default = "*" # * == All accounts in org, null == All AWS
#}
#
#variable "organization_id" {
#  type = string
#  default = null
#}
#
#variable "action" {
#  type = string
#  default = "lambda:GetLayerVersion"
#}
