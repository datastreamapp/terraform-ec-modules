# Testing Guide — terraform-ec-modules

> How to run tests for the shared Terraform modules.

---

## Prerequisites

| Tool | Version | Installation |
|------|---------|-------------|
| Terraform | >= 1.6 (for `terraform test`) | [Install](https://developer.hashicorp.com/terraform/install) |

No AWS credentials required — all tests use mock providers.

---

## Quick Start

```bash
# Run all tests for the lambda module
cd lambda
terraform init
terraform test
```

Expected output:

```
tests/artifact_source.tftest.hcl... in progress
  run "local_mode_creates_archive_file"... pass
  run "local_mode_creates_s3_object"... pass
  run "local_mode_creates_signing_job"... pass
  run "local_mode_s3_key_from_signing_job"... pass
  run "cicd_mode_skips_archive_file"... pass
  run "cicd_mode_skips_s3_object"... pass
  run "cicd_mode_skips_signing_job"... pass
  run "cicd_mode_s3_key_from_variable"... pass
  run "cicd_mode_sets_source_code_hash"... pass
  run "image_mode_skips_all_zip_resources"... pass
  run "invalid_artifact_source_rejected"... pass

Success! 11 passed, 0 failed.
```

---

## Test Inventory

| Module | Test File | Tests | Coverage |
|--------|-----------|-------|----------|
| `lambda` | `tests/artifact_source.tftest.hcl` | 11 | `artifact_source` variable: local mode, cicd mode, image mode, validation |
| `lambda-layer` | — | 0 | No tests yet |
| `lambda-dlq` | — | 0 | No tests yet |

---

## Test Details: `lambda/tests/artifact_source.tftest.hcl`

Tests the `artifact_source` variable introduced in v4.2.0.

### What's Tested

| # | Test | Mode | Asserts |
|---|------|------|---------|
| 1 | `local_mode_creates_archive_file` | local | `archive_file` count = 1 |
| 2 | `local_mode_creates_s3_object` | local | `aws_s3_object` count = 1 |
| 3 | `local_mode_creates_signing_job` | local | `aws_signer_signing_job` count = 1 |
| 4 | `local_mode_s3_key_from_signing_job` | local | `s3_key` = signing job output |
| 5 | `cicd_mode_skips_archive_file` | cicd | `archive_file` count = 0 |
| 6 | `cicd_mode_skips_s3_object` | cicd | `aws_s3_object` count = 0 |
| 7 | `cicd_mode_skips_signing_job` | cicd | `aws_signer_signing_job` count = 0 |
| 8 | `cicd_mode_s3_key_from_variable` | cicd | `s3_key` = `artifact_s3_key` variable |
| 9 | `cicd_mode_sets_source_code_hash` | cicd | `source_code_hash` = `artifact_hash` variable |
| 10 | `image_mode_skips_all_zip_resources` | cicd+Image | All ZIP resources skipped |
| 11 | `invalid_artifact_source_rejected` | invalid | Validation error |

### Test Fixtures

Tests use minimal fixtures in `tests/fixtures/`:

| File | Purpose |
|------|---------|
| `index.mjs` | Minimal Lambda handler |
| `package.json` | Required by module `locals.tf` (reads `description` field) |

### Mock Providers

All tests use `mock_provider` blocks — no real AWS calls are made. Key mocks:

- `aws_iam_policy_document` — returns valid JSON policy
- `aws_iam_role` / `aws_iam_policy` — returns valid ARNs
- `aws_signer_signing_job` — returns `signed_object` with S3 path
- `archive` — fully mocked (no file system operations)

---

## Known Warnings

`data.aws_region.current.name` produces deprecation warnings on AWS provider 5.x. The `.name` attribute is deprecated in favor of `.region`, but `.region` does not exist until provider 6.x. This is accepted until the provider 6 upgrade. See `docs/DECISIONS.md` → "Revert Provider 6 Attribute Changes".

---

## Adding New Tests

1. Create a `.tftest.hcl` file in the module's `tests/` directory
2. Use `mock_provider` blocks — avoid requiring AWS credentials
3. Add test fixtures to `tests/fixtures/` if needed
4. Run `terraform init && terraform test` from the module directory
5. Update this document with the new test inventory

---

## References

- [Terraform Test Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Mock Providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
- Decisions: `docs/DECISIONS.md`
