# Coder workspace template: `kubernetes`

A Coder workspace template that runs each workspace as a Kubernetes Deployment in
the **`ai`** namespace, with a persistent `ceph-filesystem` (Rook CephFS) home
volume. It is the source of truth for what gets pushed to Coder; the live copy
lives in Coder's database.

## What a workspace gets

- **code-server** on port `13337` (VS Code in the browser, and the backend for
  the VS Code *Coder* extension).
- **OpenCode 2** installed into the persistent home (`$HOME/.opencode/bin`),
  configured to talk to the in-cluster LiteLLM proxy.
- Two pod-mounted Secrets (read-only, at `/run/secrets`) so keys never enter
  Coder's DB:
  - `litellm-key-coder` → `LITELLM_API_KEY` (the `coder` LiteLLM virtual key)
  - `memini-key-opencode` → `MEMINI_API_KEY` (the shared `"opencode"` memini key)
- A `coder-workspace` ServiceAccount whose only permission is `get` on those two
  Secrets (see `app/rbac.yaml`).

The workspace `opencode.json` is written at startup and mirrors the cluster
opencode agent: the in-cluster LiteLLM endpoint (`litellm.ai.svc.cluster.local:4000`),
the memini plugin (namespace `opencode`, so workspace and local/cluster opencode
share one memory pool), and the in-cluster toolhive MCP gateway. It uses
`litellm/qwen3.8-27b` by default; other models from the `coder` key's model list
are selectable.

## One-time setup (in order)

Do these **before** pushing the template. Steps 1–2 are the only manual,
out-of-repo actions; everything else converges from this repo.

1. **Seed the 1Password `coder` item with the OIDC fields.** The `coder`
   ExternalSecret templates `CODER_OIDC_CLIENT_ID` / `CODER_OIDC_CLIENT_SECRET`
   from this item, so the fields must exist before the secret can be created.
   Add to the `coder` item in the `k8s-home-ops` vault:
   - `oidc_id` = `coder`
   - `oidc_secret` = a long random string (e.g. `openssl rand -hex 32`)
2. **Create the authentik OIDC application.**
   ```sh
   cd terraform/authentik
   just tofu          # or: tofu apply
   ```
   This creates the confidential `coder` OAuth2 app (group `AI`,
   `auth_groups = authentik_group.users`) and writes the generated
   `client_id` / `client_secret` back into the 1Password `coder` item.
3. **Commit and push** these repo changes. Flux then creates the `coder`
   secret (OIDC fields + Postgres init), the `coder-workspace` ServiceAccount
   / Role, the `coder` LiteLLM virtual key (which generates
   `litellm-key-coder` and pushes it to 1Password as `litellm.coder_api_key`),
   and the `memini-key-opencode` secret.
4. **Create the first Coder user.** Coder is already running (release
   `ai/coder.v13`). Log in and authenticate via authentik:
   ```sh
   coder login https://coder.ctec.run
   ```
   The **first** user to sign in over OIDC becomes admin.
5. **Push the template.**
   ```sh
   coder templates push kubernetes/apps/ai/coder/templates/kubernetes/ kubernetes
   ```
   Then create a workspace from it in the dashboard.

## Using from VS Code

1. Install the **Coder** extension.
2. Run **Coder: Connect to Coder**, select `https://coder.ctec.run` and sign in
   via authentik.
3. Pick a workspace and open it. VS Code proxies to the workspace's
   code-server. The `opencode` CLI is available in the integrated terminal,
   pre-authenticated against LiteLLM and memini.

## Notes

- **Re-push after edits.** The template's source of truth is this file; the copy
  in Coder's DB is a snapshot. After changing `main.tf`, re-run
  `coder templates push` to apply the change to existing/new workspaces.
- **Keys stay out of Coder.** No API key is stored in Coder's Postgres — the
  provisioner mounts the Secrets directly into the pod, and the `coder-workspace`
  ServiceAccount can only `get` those two Secrets.
- **Tuning.** CPU / memory are mutable workspace parameters; the home disk size
  is fixed at creation time (it is the PVC size).
