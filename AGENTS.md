# AGENTS.md

Guidance for AI agents working in this repo.

## What this is

GitOps homelab: a Talos Linux cluster (3 control-plane nodes + 1 dGPU worker) running Kubernetes, reconciled by Flux v2. The repo **is** the cluster — everything under `kubernetes/` converges from git. It also holds OpenTofu projects for non-k8s infra (Cloudflare DNS, Authentik, Garage) and docker-compose stacks that doco-cd deploys onto the TrueNAS SCALE box.

Inspired by Truxnell/home-cluster and the home-operations (bjw-s) ecosystem.

**This is a live, in-use home cluster. Treat every change as a production change.**

## Repository layout

| Path | Purpose |
|---|---|
| `kubernetes/` | Everything Flux applies. `flux/cluster/ks.yaml` (root Kustomization), `apps/<namespace>/<app>/` (workloads), `components/` (reusable kustomize Components). Has its own `AGENTS.md`. |
| `talos/` | Talos machine configs via topf (`topf.yaml`, `schematics/`, `patches/`, `secrets.sops.yaml`). `output/` is gitignored. Has its own `AGENTS.md`. |
| `bootstrap/` | One-shot provisioning of **fresh** hardware: `kustomize/personal/` (flux-system GitRepository + base secrets) and `helmfile/` (CRDs + first apps). Has its own `AGENTS.md`. |
| `terraform/` | OpenTofu (`.tofu` files): `cloudflare/`, `authentik/`, `garage/`. Has its own `AGENTS.md`. |
| `docker/` | docker-compose stacks deployed by doco-cd on TrueNAS from this repo (`docker/truenas/`); `docker/.archive/` is retired stacks. Secrets are 1Password `op://` references (`.doco-cd.yaml`). |
| `tools/` | One-shot scripts and debug manifests (e.g. `wipe-rook.yaml`, `postgres-backup.yaml`). Most `app-*` generators are **legacy** (they reference a `templates/` dir that no longer exists) — read before running. |
| `.github/workflows/` | CI: `flux-local` test/diff on `kubernetes/**`, image-pull, renovate, labeler/label-sync, codeql, release, schemas (publishes flux2-schemas to `k8s-schemas.home-operations.com`). |
| `.renovate/` + `.renovaterc.json5` | Renovate config: semantic commits, automerge, `area/*` + `renovate/*` labels, presets from `home-operations/renovate-presets`. |

## Toolchain

- **just** is the task runner. The root `.justfile` includes modules: run `just` to list everything, `just kube <recipe>`, `just talos <recipe>`, `just bootstrap <recipe>`.
- **direnv + sops**: the root `.envrc` decrypts `secrets.sops.yaml` (age key at `~/.config/sops/age/keys.txt`) into the shell environment; `terraform/.envrc` does the same for `terraform/secrets.sops.yaml`. `use_sops <path>` loads any other sops env file.
- **minijinja + 1Password**: `just template <file.j2>` renders a minijinja template with environment injected via `op inject` (settings in `.minijinja.toml`). Used by bootstrap to render the personal manifests.
- **pre-commit**: yamllint (config `.github/yamllint-config.yaml`), end-of-file/line-ending/trailing-whitespace fixes, forbid CRLF/tabs, `sops-pre-commit` (forbid-secrets), gitleaks, smart-quote fix, json5 check. Run `pre-commit run --all-files` before committing.
- **flux-local**: used by CI and by `just kube apply-ks` to render/validate Kustomizations without a cluster.
- **Renovate** owns version updates (image tags, chart versions, Talos/K8s versions, action digests, `docker/` compose images). Do not hand-edit versions it manages; use `# renovate:` directives when you need to influence it (e.g. `datasource=docker depName=...` on Talos/K8s versions in `talos/topf.yaml`).

## Global conventions

- **YAML style**: 2-space indent, LF endings, no tabs, no smart quotes, no trailing whitespace, `---` document start, newline at EOF, `# yaml-language-server: $schema=...` as the first line (enforced or auto-fixed by pre-commit; yamllint uses `.github/yamllint-config.yaml`).
- **Secrets** live only in `*.sops.yaml` / `*.sops.env` (age-encrypted; key groups in `.sops.yaml`: user key everywhere, `flux` key added for `kubernetes/**.sops.yaml`, extra `truenas` key for `docker/truenas/*.sops.env`). Never commit plaintext secrets. k8s Secrets only encrypt `data:`/`stringData:`.
- **Never commit**: `kubeconfig`, `talosconfig`, terraform state / `.terraform/`, `talos/output/`, `*.agekey`/`*.pub` (all gitignored; gitleaks + pre-commit will reject anyway).
- **Commits**: semantic commit messages; CODEOWNERS is `@cbc02009`; the labeler applies `area/<dir>` labels per changed directory.
- **Validating `kubernetes/**` changes** (same commands CI runs — run before pushing):
  ```bash
  flux-local test --all-namespaces --enable-helm --path kubernetes/flux/cluster
  flux-local diff kustomization --path kubernetes/flux/cluster
  ```

## Network / cluster reference

- Public domain `ctec.run`, internal domain `ctec.internal`; API server `https://k8s.internal:6443`.
- Nodes: `uiharu` 10.0.2.10, `miri` 10.0.2.11, `sakura` 10.0.2.12 (control-plane); `mayne` 10.0.2.13 (worker, dGPU).
- TrueNAS SCALE box "shana" at `shana.ctec.internal` (10.0.2.4) — where the `docker/` stacks run.
- Postgres at 10.6.0.20 (`kubernetes/apps/databases`), service net `10.10.0.0/16`, pod net `10.11.0.0/16`.
- Cluster-wide Kustomize substitutes available to every app: `PUBLIC_DOMAIN`, `PRIVATE_DOMAIN`, `CONFIG_TRUENAS_HOST`, `CONFIG_TRUENAS_IP`, `CONFIG_TZ` (see `kubernetes/flux/cluster/ks.yaml`).

## Safety

- Destructive operations exist as `just` recipes with confirm prompts and as one-shot manifests in `tools/` (`reset-node`, `reset-cluster`, `wipe-rook.yaml`, `delete-stuck-ns.sh`, ...). **Do not run destructive recipes or manifests without an explicit, current instruction from the user.**
- **Never run `just bootstrap` against the running cluster** — it is for bare-metal/fresh nodes only.
- Avoid touching `kube-system` (Cilium, CoreDNS), Rook-Ceph, or node resets unless explicitly asked.
- `prune: true` is the norm: deleting a file from the repo deletes the resource in-cluster. Keep paths and resource names stable when refactoring.
- When a change is uncertain, prefer making the edit in-repo and letting Flux converge, and validate with `flux-local` first.
