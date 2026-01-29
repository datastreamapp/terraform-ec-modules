data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  aws_region = data.aws_region.current.name
  description = var.description != "" ? var.description : jsondecode(file("${var.source_dir}/package.json")).description
  env        = merge({
    ACCOUNT_ID                          = local.account_id
    #NODE_OPTIONS                        = "--experimental-json-modules"
    # AWS_NODEJS_CONNECTION_REUSE_ENABLED = 1 # No longer need w/ AWS SDK
    # AWS_USE_FIPS_ENDPOINT               = "TRUE" # { useFipsEndpoint: true }
    # https://docs.aws.amazon.com/xray/latest/devguide/xray-sdk-nodejs-configuration.html#xray-sdk-nodejs-configuration-envvars
    #AWS_XRAY_CONTEXT_MISSING            = "LOG_ERROR"
    #AWS_XRAY_DAEMON_ADDRESS             = "0.0.0.0:2000" # Not required because running with awsvpc network mode
    #AWS_XRAY_DEBUG_MODE                 = "TRUE"

    NODE_ENV                            = terraform.workspace
  }, var.env)
}
