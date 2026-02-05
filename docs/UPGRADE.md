# Upgrade Guide — terraform-ec-modules

> Migration guides for upgrading between module versions.

---

## v3.2.0 → v4.2.0

### Overview

v4.2.0 adds support for CI/CD pre-built artifacts in the `lambda` and `lambda-layer` modules. This is a **backward-compatible** release — existing configurations work without changes.

### What's New

| Module | New Variables | Purpose |
|--------|--------------|---------|
| `lambda` | `artifact_source`, `artifact_s3_key`, `artifact_hash` | CI/CD pre-built artifact support |
| `lambda-layer` | `artifact_source`, `artifact_s3_key`, `artifact_hash` | CI/CD pre-built artifact support |

### Provider Constraint Change

The AWS provider constraint was relaxed from `>= 6.0` to `>= 5.0` for all modules (`lambda`, `lambda-layer`, `lambda-dlq`). This allows consumers using AWS provider 5.x to upgrade without a provider change.

| Module | Old Constraint | New Constraint |
|--------|---------------|----------------|
| `lambda` | `>= 6.0` | `>= 5.0` |
| `lambda-layer` | `>= 6.0` | `>= 5.0` |
| `lambda-dlq` | `>= 6.0` | `>= 5.0` |

### Migration Steps

**Step 1: Update module source version**

```hcl
# Before
module "my-lambda" {
  source = "git::https://github.com/datastreamapp/terraform-ec-modules.git//lambda?ref=v3.2.0"
  # ...
}

# After
module "my-lambda" {
  source = "git::https://github.com/datastreamapp/terraform-ec-modules.git//lambda?ref=v4.2.0"
  # ...
}
```

**Step 2: Run terraform init**

```bash
terraform init -upgrade
```

**Step 3: Run terraform plan**

```bash
terraform plan
```

You should see **no changes** — the default `artifact_source = "local"` preserves existing behavior.

### No Breaking Changes

- Default behavior is unchanged (`artifact_source = "local"`)
- All existing variables continue to work
- No resource recreation required
- No state migration required

### Using CI/CD Mode (Optional)

To switch a Lambda to CI/CD pre-built artifacts:

```hcl
module "my-lambda" {
  source = "git::https://github.com/datastreamapp/terraform-ec-modules.git//lambda?ref=v4.2.0"

  # New variables for CI/CD mode
  artifact_source  = "cicd"
  artifact_s3_key  = "signed/my-handler-abc123.zip"  # Pre-signed artifact in S3
  artifact_hash    = "abc123def456..."               # Base64-encoded SHA256 hash

  # Existing variables unchanged
  name        = "my-lambda"
  source_dir  = "${path.module}/handlers/my-handler"
  # ...
}
```

**Note:** When `artifact_source = "cicd"`:
- `artifact_s3_key` is **required** — the S3 key of the pre-signed artifact
- `artifact_hash` is **required** for ZIP packages — enables Lambda change detection
- `source_dir` is still required (used for description fallback) but the code is not zipped locally

### Rollback

To revert to local builds, set `artifact_source = "local"` (or remove the variable entirely):

```hcl
module "my-lambda" {
  source = "git::https://github.com/datastreamapp/terraform-ec-modules.git//lambda?ref=v4.2.0"

  # Remove or set to "local"
  artifact_source = "local"
  # artifact_s3_key and artifact_hash can be removed

  # ...
}
```

### Known Warnings

You may see deprecation warnings about `data.aws_region.current.name`:

```
Warning: Deprecated attribute
  The attribute "name" is deprecated. Refer to the provider documentation for details.
```

This is expected and harmless. The `.name` attribute works on AWS provider 5.x (with warning) and will be replaced with `.region` when upgrading to provider 6.x.

---

## References

- [CHANGELOG.md](../CHANGELOG.md) — Full release notes
- [DECISIONS.md](DECISIONS.md) — Technical decisions and rationale
- [TESTING.md](TESTING.md) — Test inventory and how to run tests
