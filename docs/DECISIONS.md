# Decisions Log — terraform-ec-modules

> Technical decisions and rationale for the shared Terraform modules.

---

### Lock Files (2026-01-29)
Decision: `.terraform.lock.hcl` is gitignored.

Rationale: Shared modules are not root modules — they don't own provider version pinning. Each consumer generates its own lock file via `terraform init`, which pins provider versions for that deployment context. Committing a lock file here would conflict with consumers using different provider versions within the allowed constraint range (e.g., `>= 6.0`).

Reference: [HashiCorp — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

---

### AWS Provider Constraint: >= 5.0 (2026-01-29)
Decision: Relaxed AWS provider constraint from `>= 6.0` to `>= 5.0` for `lambda`, `lambda-layer`, and `lambda-dlq` modules.

Finding: The `v4.0.0` tag (commit `b098cfc`) bumped all modules to `>= 6.0`, but this was never deployed. The infrastructure repo (`datastreamapp/infrastructure`) was never updated to consume v4.0.0 or v4.0.1 — all 46 lambda module references still point to `v3.2.0`.

Evidence:

| Source | Constraint | Actual Version |
|--------|-----------|----------------|
| `infrastructure/terraform/environments/core/versions.tf:7` | `~> 5.0` | — |
| `infrastructure/.terraform.lock.hcl` | `>= 4.0.0, >= 5.0.0, ~> 5.0` | `v5.100.0` |
| `terraform version` (development workspace) | — | `hashicorp/aws v5.100.0` |
| All environments (dev, staging, prod) share same `versions.tf` | `~> 5.0` | `v5.100.0` |

Module version usage in infrastructure repo:

| Module Version | References | Status |
|---------------|-----------|--------|
| `v3.2.0` | 46 | Active — all lambda modules |
| `v3.0.2` | 4 | Active — lambda-layer modules |
| `v4.0.0` | 0 | Never consumed |
| `v4.0.1` | 0 | Never consumed (current master) |

Rationale: The v4.2.0 changes (`artifact_source`, count guards, `source_code_hash`) use no provider 6-specific features. Setting `>= 5.0` allows the infrastructure repo to consume v4.2.0 without a provider upgrade. The provider 6 upgrade is a separate effort.

---

### Revert Provider 6 Attribute Changes (2026-01-29)
Decision: Reverted `data.aws_region.current.region` back to `data.aws_region.current.name` in `lambda` and `lambda-dlq` modules.

Finding: Commit `42c1de5` ("chore: remove deprecated", author: will Farrell) changed 8 occurrences of `.name` to `.region` across 3 files. The attribute `.region` does not exist on `data.aws_region` in AWS provider 5.x — the correct attribute is `.name`. This change was part of the provider 6 preparation but introduced an incompatibility with provider 5.

Files affected:

| File | Occurrences |
|------|------------|
| `lambda/locals.tf:6` | 1 |
| `lambda/cloudwatch.tf:43,63,84,113,133,147` | 6 |
| `lambda-dlq/main.tf:113` | 1 |

Provider compatibility:

| Provider | `.name` | `.region` |
|----------|---------|-----------|
| 5.x (current) | Works (deprecated warning) | Does not exist — errors |
| 6.x (future) | Removed — errors | Works |

Impact: Without this revert, any consumer using AWS provider 5.x would get `Unsupported attribute` errors when referencing the module at v4.0.1+. This explains why v4.0.0/v4.0.1 were never consumed by the infrastructure repo. The deprecation warning on `.name` is accepted until the provider 6 upgrade, which is a separate effort.

---

### Preconditions for CI/CD Mode Validation (2026-02-04)
Decision: Added `lifecycle.precondition` blocks on `aws_lambda_function.lambda` to validate required variables in cicd mode.

Finding: Without preconditions, a user could set `artifact_source = "cicd"` while omitting `artifact_s3_key` or `artifact_hash`. This would result in confusing AWS API errors at apply time (null `s3_key`) or silent deployment failures (`source_code_hash = null` causes Lambda to skip code updates when the S3 object changes).

Preconditions added:

| Precondition | Condition | Failure Mode Without It |
|-------------|-----------|------------------------|
| `artifact_s3_key` required in cicd mode | `artifact_source != "cicd" \|\| artifact_s3_key != null` | AWS API error at apply — null S3 key |
| `artifact_hash` required in cicd+Zip mode | `artifact_source != "cicd" \|\| package_type != "Zip" \|\| artifact_hash != null` | Silent failure — deploys succeed but code doesn't update |

Rationale: Preconditions run during `terraform plan`, giving users clear error messages before any infrastructure changes are attempted. The second failure mode (silent code skip) is the most dangerous — deploys appear successful but the function runs stale code.

---

### Description Guard for CI/CD Mode (2026-02-04)
Decision: Hardened the `locals.tf` description condition from `var.description != ""` to `var.description != null && var.description != ""`.

Finding: The `description` variable defaults to `null`. In Terraform, `null != ""` evaluates to `true`, so the `file()` call to read `package.json` is short-circuited by accident. However, if a user explicitly passes `description = ""`, Terraform would attempt to read `package.json` from `source_dir`, which may not exist in a pure CI/CD context where source code is not present locally.

Impact: Prevents a confusing `file not found` error when `description = ""` is explicitly set in cicd mode.
