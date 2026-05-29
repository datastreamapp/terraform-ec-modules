module "lambda-dlq" {
  # Per AWS provider v6 docs: count/for_each values must be known before apply.
  # Conditioning on var.dead_letter_arn (which may receive a computed resource
  # ARN) causes a plan-time error in v6. Fix: use an explicit bool variable
  # var.create_dlq that the consumer sets at configuration time — bool literals
  # are always plan-time known regardless of other computed values.
  # Ref: https://developer.hashicorp.com/terraform/language/meta-arguments/count
  count             = var.create_dlq ? 1 : 0
  source            = "../lambda-dlq"
  name              = var.name
  kms_master_key_id = var.kms_key_arn
}

resource "aws_iam_role_policy_attachment" "lambda-dlq" {
  count      = var.create_dlq ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = module.lambda-dlq[0].policy_arn
}
