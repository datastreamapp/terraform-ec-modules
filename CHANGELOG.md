# Changelog

All notable changes to terraform-ec-modules are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [v4.2.1] — 2026-05-05

### Fixed
- **lambda**: `aws_s3_object.lambda` — add `lifecycle { ignore_changes = [object_lock_mode, object_lock_retain_until_date] }` to prevent recurring drift when S3 bucket has a default Object Lock GOVERNANCE retention policy. Without this, every plan after object creation computes drift on the bucket-applied retention attributes and attempts `PutObjectRetention` to clear them; AWS rejects the call with `405 MethodNotAllowed`, blocking apply. The module does not manage retention — the bucket's default policy owns it. Fixes #1846.
- **lambda-layer**: same fix on `aws_s3_object.layer` (`lambda-layer/lambda.tf`). Fixes #1846.

---

## [v4.2.0] — 2026-02-05

### Added
- **lambda**: `artifact_source` variable (`"local"` | `"cicd"`) for CI/CD pre-built artifact support
- **lambda**: `artifact_s3_key`, `artifact_hash` variables for cicd mode
- **lambda**: `source_code_hash` on `aws_lambda_function` for cicd change detection
- **lambda**: 14 tests in `lambda/tests/artifact_source.tftest.hcl` (10 positive, 4 negative)
- **lambda-layer**: `artifact_source` variable (`"local"` | `"cicd"`) for CI/CD pre-built artifact support
- **lambda-layer**: `artifact_s3_key`, `artifact_hash` variables for cicd mode
- **lambda-layer**: `source_code_hash` on `aws_lambda_layer_version` for cicd change detection
- **lambda-layer**: 13 tests in `lambda-layer/tests/artifact_source.tftest.hcl` (9 positive, 4 negative)
- `docs/DECISIONS.md` — technical decisions log
- `docs/TESTING.md` — test inventory and guide
- `docs/RETROSPECTIVE.md` — epic retrospective template

### Changed
- **lambda, lambda-layer, lambda-dlq**: relaxed AWS provider constraint `>= 6.0` → `>= 5.0`
- **lambda, lambda-dlq**: reverted `data.aws_region.current.region` → `.name` (provider 5 compat)
- `.gitignore` — added `.terraform.lock.hcl` (shared modules don't own lock files)

### Fixed
- **lambda, lambda-dlq**: provider 5 compatibility — `.region` attribute does not exist on `data.aws_region` in provider 5.x
