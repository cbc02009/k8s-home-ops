---
name: uses-opentofu-not-terraform
description: IaC in this repo is managed with OpenTofu (tofu), not Terraform
metadata:
  type: project
---

This repo's IaC (under `terraform/`) is managed with **OpenTofu**, not Terraform. Use `tofu` commands (`tofu init`, `tofu plan`, `tofu apply`, `tofu fmt`), not `terraform`. The files are HCL `.tf`/`.tofu` and are compatible with both, but the user expects OpenTofu to be the tool of record.

OpenTofu v1.13.2 is installed on the local host at `/usr/bin/tofu`. Note `terraform/authentik` uses a `pg` backend (`postgres://postgres.ctec.run/terraform`, schema `authentik`), so `tofu init` there needs the pg backend plugin available.
