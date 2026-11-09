# talos/ — Talos Linux machine configs

Cluster `home-ops` (API server `https://k8s.internal:6443`): `uiharu`/`miri`/`sakura` = control-plane (10.0.2.10–12), `mayne` = worker with dGPU (10.0.2.13).

## Sources of truth (topf)

- `topf.yaml` — the topf cluster definition: Talos and Kubernetes versions (Renovate-managed via `# renovate: datasource=docker depName=...` directives), node list with IPs/roles, `patchesDir: patches`, `secretsPath: secrets.sops.yaml`, and per-node `schematicId: "@schematics/<file>.yaml"`.
- `schematics/` — Talos Factory schematic requests (base image extensions): `control-plane.yaml` (Intel iGPU, ucode, nfsrahead, ...) and `mayne.yaml` (NVIDIA open kernel modules + container toolkit). `just talos gen-schematic-id` POSTs a schematic to the factory to mint/update the ID.
- `patches/` — machine config patches, layered: `all/` (every node) → `control-plane/` / `worker/` (by role) → `node/<hostname>/` (per-host: volumes, network, install, kernel modules).
- `secrets.sops.yaml` — age-encrypted (user key only), decrypted by topf.

## Gitignored — never commit or echo

- `output/` — rendered per-node machine configs (contain secrets).
- `talosconfig` — topf-generated client config with an admin private key.

## Operations

- Render: `topf` (produces `output/<node>.yaml`).
- `just talos apply-node <node> [args]` — `talosctl apply-config` (add `--insecure` on first-ever apply).
- `just talos reboot-node <node>`, `upgrade-node <node>`, `upgrade-k8s <version>` (both confirm before acting).
- `just talos download-image <version> [node]` — fetches the factory ISO for a node's schematic.
- **Destructive:** `just talos reset-node <node>` / `reset-cluster` wipe node system state. Only with an explicit, current instruction from the user.

## Gotchas

- `talconfig.yaml`, `talhelper-secrets.env`, and `just talos talhelper-genconfig` are the **legacy talhelper** flow, superseded by topf (see `.gitignore` note about `clusterconfig/`). Prefer topf; do not extend talhelper.
- `just talos render-config` / `machine-controller` reference jinja templates that no longer exist (`machineconfig.yaml.j2`, `nodes/*.yaml.j2`) — do not use them.
- `just talos apply-node` still points at `clusterconfig/home-ops-<node>.yaml` (the talhelper output dir); if that file is absent, apply from the topf output: `talosctl apply-config -n <node> -f output/<node>.yaml`.
- Adding a node: add it to `topf.yaml` (`nodes:`), create `patches/node/<hostname>/` (copy from an existing host of the same role), and a schematic if it needs different base extensions.
