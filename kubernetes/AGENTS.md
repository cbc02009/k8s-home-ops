# kubernetes/ — Flux-managed cluster state

Flux pulls this tree from the GitRepository `flux-system` (bootstrapped from `../bootstrap/kustomize/personal/flux-system/`). The root Kustomization is `flux/cluster/ks.yaml` (`cluster-apps`); it reconciles every app `ks.yaml` and injects cluster-wide defaults into all children via `patches` (HelmRelease `crds: CreateReplace`, `cleanupOnFail: true`, remediation `remediateLastFailure`/`retries: 2`, and `postBuild.substitute` for `PUBLIC_DOMAIN`, `PRIVATE_DOMAIN`, `CONFIG_TRUENAS_HOST`, `CONFIG_TRUENAS_IP`, `CONFIG_TZ`). **Do not repeat those defaults in individual apps.**

## Layout

```
kubernetes/
├── flux/cluster/ks.yaml        # Root Kustomization + cluster-wide default patches
├── components/                 # Reusable kustomize Components (v1alpha1): common, pvc, gpu,
│                               #   igpu-spread, kopiur, zeroscaler, dragonfly, authentik-proxy
└── apps/
    └── <namespace>/            # ai, cert-manager, databases, default, flux-system, home,
        ├── kustomization.yaml  #   kguardian, kube-system, network, observability, openebs,
        │                       #   rook-ceph, security, system, system-upgrade
        ├── namespace.yaml
        └── <app>/
            ├── ks.yaml         # Flux Kustomization(s), one document per section
            ├── app/            # The chart release:
            │   ├── kustomization.yaml
            │   ├── helmrelease.yaml
            │   ├── ocirepository.yaml
            │   ├── externalsecret.yaml    # optional
            │   ├── grafanadashboard.yaml  # optional
            │   └── resources/             # optional (Renovate ignores **/resources/**)
            └── <section>/      # optional extra sections, e.g. cloudnative-pg/{barman-cloud,cluster}
```

## `ks.yaml` conventions (see `apps/databases/cloudnative-pg/ks.yaml`, `apps/home/frigate/ks.yaml`)

- YAML anchors: `name: &app <name>` and `namespace: &namespace <ns>`; `targetNamespace: *namespace`; `commonMetadata.labels.app.kubernetes.io/name: *app`.
- `interval: 30m`, `prune: true` (exception: `flux-system/flux-operator` and `flux-system/flux-instance` use `prune: false` — they must never be deleted), `wait: false`, `timeout: 5m` for Helm-backed ones.
- `sourceRef`: `kind: GitRepository`, `name: flux-system`, `namespace: flux-system`.
- `path`: repo-relative, `./kubernetes/apps/<ns>/<app>[/<section>]`.
- `dependsOn` for ordering (cross-namespace ones include `namespace:`); add `healthChecks` for CRs where readiness matters (see `databases/cloudnative-pg` for `postgresql.cnpg.io/v1` clusters).
- `components:` pulls shared pieces, e.g. frigate uses `../../components/{gpu,igpu-spread,kopiur,zeroscaler}`.
- `postBuild.substitute` / `substituteFrom` for per-app values (`APP`, `PVC_CAPACITY`, `OLD_NS`, fixed IPs, Secret references).

## Charts and images

- Prefer the `app-template` chart (bjw-s-labs) delivered as an `OCIRepository` from `oci://ghcr.io/bjw-s-labs/helm/app-template`, keeping the `layerSelector` and cosign `verify` blocks (copy an existing `ocirepository.yaml`).
- Keep image references Renovate-manageable (plain `registry/image:tag`); Renovate parses `*.yaml`/`*.yaml.j2` here.

## Secrets

- In-cluster: sops-encrypted `*.sops.yaml` files (only `data:`/`stringData:` encrypted; decryptable by the user + `flux` age keys).
- 1Password: ExternalSecrets — operator and cluster secret store live in `apps/security/onepassword-connect/`; per-app `externalsecret.yaml` files pull from `op://` (e.g. `apps/security/authentik`, `apps/network/*`). Apps with an `externalsecret.yaml` should `dependsOn` the external-secrets app (`security` namespace) where not already handled.

## Adding a new app

1. Copy the closest existing app (e.g. `ai/hermes` for a simple one, `databases/cloudnative-pg` for multi-section) into `apps/<ns>/<newapp>/`.
2. Write `app/` (`kustomization.yaml`, `helmrelease.yaml`, `ocirepository.yaml`) and `ks.yaml` following the conventions above; update `name`/`path`/`dependsOn`.
3. Register the app in `<ns>/kustomization.yaml` (list its `ks.yaml`); for a brand-new namespace, add `namespace.yaml` and the `kustomization.yaml` (pull in `../../components/common`).
4. Add any needed secret (sops file or ExternalSecret) and `dependsOn` for it.
5. Validate: `flux-local test --all-namespaces --enable-helm --path kubernetes/flux/cluster`; CI posts a `flux-local diff` on the PR.
6. Manually sync from a workstation: `just kube ks-sync <ns> <ks>` (also `hr-sync`, `gr-sync`, `es-sync` and `*-all` variants; `apply-ks`/`delete-ks` apply a Kustomization directly with `flux-local build`).

## Gotchas

- `prune: true` is the norm — deleting or renaming a file deletes the resource in-cluster on the next reconcile.
- The generators in `tools/` (`app-folder-gen.sh`, `app-kustomize-gen.sh`) are legacy: they reference a `templates/` directory that no longer exists and predate the current anchor/component style. Do not run them or mimic their output.
- Historical convention: a `wip` file inside an app dir disabled its Kustomization (the old generator commented it out of the namespace kustomization). With hand-maintained kustomizations today, just comment out the `ks.yaml` entry in `<ns>/kustomization.yaml`.
- `flux-system/` (flux-operator + flux-instance) is the foundation — change it last and with care.
- Grafana dashboards: `grafanadashboard.yaml` + JSON files under `resources/` (or `app/dashboard/`).
