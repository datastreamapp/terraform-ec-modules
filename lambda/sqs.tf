module "lambda-dlq" {
  # for_each replaces the previous count = var.dead_letter_arn == null ? 1 : 0
  # pattern, which AWS provider v6 rejects when dead_letter_arn receives a
  # computed resource ARN (unknown at plan time). for_each with a static set
  # is always knowable at plan time regardless of what dead_letter_arn holds.
  for_each          = var.dead_letter_arn == null ? toset(["main"]) : toset([])
  source            = "../lambda-dlq"
  name              = var.name
  kms_master_key_id = var.kms_key_arn
}

# State migration: module.lambda-dlq[0] → module.lambda-dlq["main"]
# Required for consumers upgrading from lambda v4.2.1 → v4.3.0.
moved {
  from = module.lambda-dlq[0]
  to   = module.lambda-dlq["main"]
}

resource "aws_iam_role_policy_attachment" "lambda-dlq" {
  for_each   = var.dead_letter_arn == null ? toset(["main"]) : toset([])
  role       = aws_iam_role.lambda.name
  policy_arn = module.lambda-dlq["main"].policy_arn
}

moved {
  from = aws_iam_role_policy_attachment.lambda-dlq[0]
  to   = aws_iam_role_policy_attachment.lambda-dlq["main"]
}
