# Decisions Log — terraform-ec-modules

> Technical decisions and rationale for the shared Terraform modules.

---

### Lock Files (2026-01-29)
**Decision:** `.terraform.lock.hcl` is gitignored.

**Rationale:** Shared modules are not root modules — they don't own provider version pinning. Each consumer generates its own lock file via `terraform init`, which pins provider versions for that deployment context. Committing a lock file here would conflict with consumers using different provider versions within the allowed constraint range (e.g., `>= 6.0`).

**Reference:** [HashiCorp — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

