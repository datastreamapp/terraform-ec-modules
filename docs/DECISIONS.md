# Decisions Log — terraform-ec-modules

> Technical decisions and rationale for the shared Terraform modules.

---

### Lock Files (2026-01-29)
**Decision:** `.terraform.lock.hcl` is gitignored.

**Rationale:** Shared modules are not root modules — they don't own provider version pinning. Each consumer generates its own lock file via `terraform init`, which pins provider versions for that deployment context. Committing a lock file here would conflict with consumers using different provider versions within the allowed constraint range (e.g., `>= 6.0`).

**Reference:** [HashiCorp — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

---

### AWS Provider Constraint: >= 5.0 (2026-01-29)
**Decision:** Relaxed AWS provider constraint from `>= 6.0` to `>= 5.0` for `lambda` and `lambda-dlq` modules.

**Finding:** The `v4.0.0` tag (commit `b098cfc`) bumped all modules to `>= 6.0`, but this was **never deployed**. The infrastructure repo (`datastreamapp/infrastructure`) was never updated to consume v4.0.0 or v4.0.1 — all 46 lambda module references still point to `v3.2.0`.

**Evidence:**

| Source | Constraint | Actual Version |
|--------|-----------|----------------|
| `infrastructure/terraform/environments/core/versions.tf:7` | `~> 5.0` | — |
| `infrastructure/.terraform.lock.hcl` | `>= 4.0.0, >= 5.0.0, ~> 5.0` | `v5.100.0` |
| `terraform version` (development workspace) | — | `hashicorp/aws v5.100.0` |
| All environments (dev, staging, prod) share same `versions.tf` | `~> 5.0` | `v5.100.0` |

**Module version usage in infrastructure repo:**

| Module Version | References | Status |
|---------------|-----------|--------|
| `v3.2.0` | 46 | Active — all lambda modules |
| `v3.0.2` | 4 | Active — lambda-layer modules |
| `v4.0.0` | 0 | Never consumed |
| `v4.0.1` | 0 | Never consumed (current master) |

**Rationale:** The v4.2.0 changes (`artifact_source`, count guards, `source_code_hash`) use no provider 6-specific features. Setting `>= 5.0` allows the infrastructure repo to consume v4.2.0 without a provider upgrade. The provider 6 upgrade is a separate effort.

---

### Revert Provider 6 Attribute Changes (2026-01-29)
**Decision:** Reverted `data.aws_region.current.region` back to `data.aws_region.current.name` in `lambda` and `lambda-dlq` modules.

**Finding:** Commit `42c1de5` ("chore: remove deprecated", author: will Farrell) changed 8 occurrences of `.name` to `.region` across 3 files. The attribute `.region` does not exist on `data.aws_region` in AWS provider 5.x — the correct attribute is `.name`. This change was part of the provider 6 preparation but introduced an incompatibility with provider 5.

**Files affected:**

| File | Occurrences |
|------|------------|
| `lambda/locals.tf:6` | 1 |
| `lambda/cloudwatch.tf:43,63,84,113,133,147` | 6 |
| `lambda-dlq/main.tf:113` | 1 |

**Impact:** Without this revert, any consumer using AWS provider 5.x would get `Unsupported attribute` errors when referencing the module at v4.0.1+. This explains why v4.0.0/v4.0.1 were never consumed by the infrastructure repo.
