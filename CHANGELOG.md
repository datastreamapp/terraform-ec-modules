# Changelog

All notable changes to terraform-ec-modules are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/).

---

## [v4.3.1] — 2026-06-23

### Fixed
- **lambda, lambda-layer**: pass `aws_s3_object.key` (not `.id`) as the `aws_signer_signing_job` source key. AWS provider v6 changed `aws_s3_object.id` from the bare object key to `bucket/key`, so the signing job received a bucket-prefixed key and failed with `ResourceNotFoundException` ("S3 object ... not present"). Affects the `local` artifact_source path only — the `cicd` path leaves these resources at `count = 0`.

---

## [v4.3.0] — 2026-05-29

### Added
- **lambda**: `create_dlq` variable (bool, default `true`) controlling whether the module provisions its own internal DLQ.
- **lambda, lambda-layer**: additional `artifact_source` cases in `tests/artifact_source.tftest.hcl`.

### Changed
- **lambda**: DLQ provisioning now keys off `create_dlq` instead of `dead_letter_arn == null`. AWS provider v6 forbids `count`/`for_each` from depending on a computed resource attribute, and `dead_letter_arn` may receive an unknown-at-plan ARN. **Breaking**: consumers passing `dead_letter_arn` must now also set `create_dlq = false`; a new precondition rejects setting both.
- **lambda, lambda-layer, lambda-dlq**: `data.aws_region.current.name` → `.region` (`.name` deprecated in provider v6).
- **lambda, lambda-layer**: cicd preconditions now require non-empty `artifact_s3_key` / `artifact_hash` (previously only non-null).

---

## [v4.2.1] — 2026-05-05

### Fixed
- **lambda, lambda-layer**: ignore `object_lock_mode` and `object_lock_retain_until_date` on `aws_s3_object` resources. When the deployment bucket has a default Object Lock retention policy, these attributes are bucket-managed and should not be tracked by the module.

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
