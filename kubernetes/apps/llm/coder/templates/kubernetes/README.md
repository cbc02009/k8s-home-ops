# Coder workspace template: `kubernetes`

A Coder workspace template that runs each workspace as a Kubernetes Deployment in
the **`llm`** namespace, with a persistent `ceph-filesystem` (Rook CephFS) home
volume. It is the source of truth for what gets pushed to Coder; the live copy
lives in Coder's database.

## What a workspace gets

- **code-server** on port `13337` (VS Code in the browser, and the backend for
  the VS Code *Coder* extension).
- **The k8s-home-ops toolchain**, installed once onto the persistent home
  (`~/.local/bin`) and skipped on later starts:
  `kubectl`, `helm`, `kustomize`, `flux`, `sops`, `age`, `direnv`, `just`,
  `tofu`, `gh`, `gitleaks`, `talosctl`, plus `yamllint`, `pre-commit` and
  `flux-local` via pipx. (Base image `codercom/example-base:ubuntu` already
  ships git, python3, pipx, jq, unzip, docker CLI.)
- **Fish + starship + atuin**, installed from `cbc02009/dotfiles` via
  `chezmoi init --apply`. code-server's integrated terminal defaults to Fish.
- **The repo cloned** to `~/git/k8s-home-ops` (over SSH, see credentials below).
- **OpenCode 2** (`$HOME/.opencode/bin`) configured against the in-cluster
  LiteLLM proxy, memini plugin (namespace `opencode`) and toolhive MCP.
- Secrets mounted read-only at `/run/secrets` — nothing is stored in Coder's DB:

  | Path | Secret (key) | Becomes |
  |---|---|---|
  | `/run/secrets/litellm/api-key` | `litellm-key-coder` | `LITELLM_API_KEY` |
  | `/run/secrets/memini/api-key` | `memini-key-opencode` | `MEMINI_API_KEY` |
  | `/run/secrets/kubeconfig/kubeconfig` | `coder-workspace` (`kubeconfig`) | `KUBECONFIG` |
  | `/run/secrets/age/keys.txt` | `coder-workspace` (`age_key`) | `~/.config/sops/age/keys.txt` (sops/direnv) |
  | `/run/secrets/ssh/id_ed25519[.pub]` | `coder-workspace` (`ssh_private`/`ssh_public`) | `~/.ssh/` + git `core.sshCommand` |

  A `coder-workspace` ServiceAccount limits workspace pods to `get` on exactly
  those three Secrets (see `app/rbac.yaml`).

## One-time setup (in order)

Everything from step 1–3 is already done except where noted; keep them here for
rebuilds.

1. **1Password `coder` item** (vault `k8s-home-ops`): fields `oidc_id`,
   `oidc_secret` — consumed by the Coder server itself for authentik OIDC. ✅ done
2. **authentik OIDC application** (`terraform/authentik`):
   `tofu apply` creates the confidential `coder` OAuth2 app. ✅ done
3. **Push these repo changes** — Flux creates the `coder` secret, the RBAC, the
   `coder` LiteLLM virtual key (→ secret `litellm-key-coder`), the
   `memini-key-opencode` secret, and the `coder-workspace` secret.
4. **Populate the 1Password fields** (vault `k8s-home-ops`) — do this **before
   creating a workspace**, because the `coder-workspace` ExternalSecret errors
   until they exist, and workspace pods sit in `ContainerCreating` without the
   Secret.

   On the existing **`coder`** item (shared with the Coder server's
   Postgres/OIDC fields), add:

   | Field | Contents |
   |---|---|
   | `kubeconfig` | contents of your workstation `kubeconfig` (cluster access) |
   | `age_key` | contents of `~/.config/sops/age/keys.txt` (personal age key) |

   And the **`coder-github-key`** item (must be a 1Password **SSH Key** item
   type — the ExternalSecret maps its built-in `private key` / `public key`
   fields to `ssh_private` / `ssh_public`, since labels with spaces can't be
   used as Secret keys via `extract`):

   | Built-in field | Used as |
   |---|---|
   | `private key` | `ssh_private` (recommended: a dedicated key) |
   | `public key` | `ssh_public` (must be added to your GitHub account) |

5. **Create the first Coder user** (first OIDC login becomes admin):
   `coder login https://coder.ctec.run` ✅ done
6. **Push the template** (re-run this whenever `main.tf` changes):
   ```sh
   coder templates push kubernetes --directory kubernetes/apps/llm/coder/templates/kubernetes
   ```
7. **Create a workspace** in the dashboard (or `coder create dev`). First start
   takes a few minutes: toolchain download + repo clone. Later starts are fast.

## Using from VS Code

1. Install the **Coder** extension.
2. **Coder: Connect to Coder** → `https://coder.ctec.run` → authentik.
3. Open the workspace and pick `~/git/k8s-home-ops`. The integrated terminal is
   a login-ish bash: `.bashrc` sources `~/.config/coder/env` (API keys,
   `KUBECONFIG`) and the direnv hook, so `direnv`/`sops`/`kubectl`/`flux` work
   exactly like on the workstation.

## Notes

- **Re-push after edits.** The repo copy of `main.tf` is the source of truth;
  Coder's DB holds a snapshot. After editing, re-run step 6, then update
  running workspaces (Versions tab → update).
- **Keys stay out of Coder.** API keys, kubeconfig, age key and SSH key are
  mounted from Kubernetes Secrets; the provisioner never copies them into its
  Postgres. Rotate by editing the 1Password items; the secret volume refreshes
  automatically within the ES refresh interval (1h) — the running shell env
  vars refresh on next terminal.
- **Cluster access is admin-equivalent** (the kubeconfig is the repo's
  kubeconfig). Deliberate: home cluster, single trust domain. The SSH key gets
  write access to the repos your GitHub account can reach.
- **Tuning.** CPU / memory are mutable workspace parameters; the home disk size
  is fixed at creation time (it is the PVC size).
