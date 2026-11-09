# terraform/ — OpenTofu projects

- **OpenTofu, not Terraform.** HCL files are `*.tofu` (formatter: the VS Code `opentofu` extension, format-on-save; `files.associations` maps `*.tofu` → opentofu). Use the `tofu` CLI.
- Projects:
  - `cloudflare/` — provider (`main.tofu`) + DNS records (`records.tofu`) for `ctec.run` / `ctec.internal`.
  - `authentik/` — identity provider configuration: applications, flows, stages, directory, customization (`modules/`, `expressions/`).
  - `garage/` — Garage object storage (backs dragonfly/opencloud in the cluster).
- **Secrets**: `terraform/secrets.sops.yaml` (age, user key) is decrypted to the environment by `terraform/.envrc` (`use_sops`); the age key file itself is exported by the repo-root `.envrc` (`~/.config/sops/age/keys.txt`). Never write secret values into `.tofu` files.
- **State**: local `terraform.tfstate` per project directory, gitignored (along with `.terraform/` and `*tfplan*`). Run `tofu init` / `tofu plan` / `tofu apply` from the project directory. Never commit state or plan files.
- **DNS coordination**: some records are also managed in-cluster by external-dns (`kubernetes/apps/network/external-dns`, Cloudflare + UniFi variants). When adding/removing hostnames, check both sides and avoid conflicting the two managers on the same record.
