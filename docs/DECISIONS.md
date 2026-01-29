# Decisions Log — terraform-ec-modules

> Technical decisions and rationale for the shared Terraform modules.

---

### Lock Files (2026-01-29)
**Decision:** `.terraform.lock.hcl` is gitignored.

**Rationale:** Shared modules are not root modules — they don't own provider version pinning. Each consumer generates its own lock file via `terraform init`, which pins provider versions for that deployment context. Committing a lock file here would conflict with consumers using different provider versions within the allowed constraint range (e.g., `>= 6.0`).

**Reference:** [HashiCorp — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

---

### Lambda Module Provider Constraint (2026-01-29)
**Decision:** Relaxed `lambda/versions.tf` AWS provider constraint from `>= 6.0` to `>= 5.0` on the `feature/1497-lambda-cicd-artifact-source` branch.

**Rationale:** The `v4.0.0` commit bumped all modules to `>= 6.0`, but the infrastructure repo (`datastreamapp/infrastructure`) uses `~> 5.0`. The provider 6 upgrade is planned after the Lambda CI/CD epic (#1497). The v4.2.0 changes (`artifact_source`, count guards, `source_code_hash`) use no provider 6-specific features.
