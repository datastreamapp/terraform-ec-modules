# terraform-ec-modules
Terraform AWS elastic Compute Modules

If making changes to volumes: https://www.terraform.io/docs/commands/taint.html



## EC2


## Bastion


## NAT


## ECS


## Development

### Lock Files
`.terraform.lock.hcl` is gitignored. Shared modules are not root modules — they don't own provider version pinning. Each consumer generates its own lock file via `terraform init`, which pins provider versions for that deployment context. Committing a lock file here would conflict with consumers using different provider versions within the allowed constraint range (e.g., `>= 6.0`).

Ref: [HashiCorp — Dependency Lock File](https://developer.hashicorp.com/terraform/language/files/dependency-lock)

## Authors
- [Kiril Kirov](https://github.com/kkirov)
- [will Farrell](https://github.com/willfarrell)
