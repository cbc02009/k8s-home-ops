# bootstrap/ — one-shot cluster bootstrap

Provisions a **brand-new** cluster end-to-end. Recipes live in `mod.just` (group: `just bootstrap`).

## Flow

1. `just bootstrap talos` — applies the Talos machine config to each node in `../talos/topf.yaml` (via `just talos::apply-node --insecure`; skips nodes already configured).
2. `just bootstrap cluster` — the rest, in order:
   - `k8s` — polls `talosctl bootstrap` until `AlreadyExists` (installs Kubernetes).
   - `kubeconfig "node"` — fetches a kubeconfig pointed at the controller's raw API address.
   - `base` — `kustomize build kustomize/personal | just template - | kubectl apply --server-side`: the flux-system GitRepository + its secret, plus base Secrets for `databases`, `network`, `security`. `just template` = minijinja + `op inject`, so 1Password items referenced here must exist.
   - `apps` — `helmfile -f helmfile/apps.yaml sync` (gotmpl templates in `helmfile/templates/`).
   - `kubeconfig` — re-fetches the kubeconfig pointed at the Cilium LB address (`k8s.internal`).
- `just bootstrap wait` / private `api-ready` / `nodes-ready` — readiness gates, useful when resuming an interrupted bootstrap.
- `helmfile/crds.yaml` — CRDs that must exist before the Flux `cluster-apps` Kustomization can reconcile (applied as part of `base`).

## Rules

- **Fresh hardware only.** Never run these recipes against the running `home-ops` cluster.
- After bootstrap, Flux takes over reconciliation from `kubernetes/` in this repo. Anything applied by bootstrap that isn't also in `kubernetes/` will be pruned — keep the two in sync.
- `kustomize/personal/**/secret.yaml` files are sops-encrypted; regenerate/rotate with sops, never plaintext.
