# Renaming namespace `ai` → `llm`

The `ai` namespace is a delegated **public TLD**. With the cluster's
`ndots:5` + DNS search suffixes, in-cluster Services shadow the public
`<name>.ai` domains: `memini.ai`, `litellm.ai` and `headroom.ai` all resolve
in-cluster to private IPs, which hangs anything that legitimately wants the
public domains (it hung every `opencode_go` lane in litellm; see the coredns
comment). This branch renames the namespace to `llm` (not a TLD) and moves
every one of its 9 data volumes across.

Delete this whole directory in a follow-up commit once the rename is done.

## What the branch changes (git)

- `git mv kubernetes/apps/ai → kubernetes/apps/llm`; `namespace:`/`targetNamespace:`/
  `path:`/`dependsOn`/healthCheck `namespace:` updated everywhere (12 app KSs).
- All FQDNs `<svc>.ai.svc.cluster.local` → `<svc>.llm.svc.cluster.local`
  (litellm models, guardrail, hermes/memini/opencode configs, toolhive virtual
  MCP, coder template, cross-ns karakeep/mealie/kguardian).
- Hermes' **short-form** URLs (`http://litellm.ai:4000`, `http://vmcp-...ai:4483`)
  → `…llm` — they only worked via the search suffix before and would hit the
  parked public domain after the rename.
- `serviceMonitor matchNames`, `ClusterRoleBinding` subjects, the
  `ai-paseo-view` → `llm-paseo-view` CRB, `MCPTelemetryConfig` namespace.
- Coder template `var.namespace` default `ai` → `llm` (+ FQDNs) — **pushed to
  Coder separately** (the template lives in Coder's DB, not the repo).
- `llmkube` `modelCache.existingClaim: llmkube-model-cache` + a git-declared
  `llmkube-model-cache.yaml` PVC (was Helm-owned) so the 200Gi ceph-filesystem
  volume survives as a rebind instead of a re-download.
- Cross-ns consumers: karakeep/mealie `proxyNamespace`, kguardian `baseUrl`.
- Talos `KubeTalosAPIAccessConfig.allowedKubernetesNamespaces: ai → llm`
  (applied later by a normal `topf apply` — the branch also carries the
  Renovate k8s 1.37.2 bump, so it is a separate, operator-driven event).
- coredns comment updated to tell the future story.

## How each of the 9 PVCs moves

| PVC | Volume | Method |
|---|---|---|
| hermes, litellm, memini, opencode, open-webui | RBD / CephFS, 1–20Gi | **kopiur cross-ns restore** (`restores/*.yaml`, source pinned to the `ai` policy + `/pvc/<app>`; `target.pvc` creates the new claim) |
| llmkube-mayne-cache | 200Gi openebs-hostpath | **PV rebind** (Retain → repoint `claimRef` → `volumeName`) — zero-copy, models stay |
| llmkube-model-cache | 200Gi CephFS (6 pods mount it) | **PV rebind** — zero-copy |
| paseo | 20Gi RBD (new, daemon state) | **PV rebind** |
| coder-…-home (half-set-up Coder workspace; ~16K of IDE scaffolding) | 10Gi CephFS | **PV rebind to Available**; the Coder terraform PVC (same class/modes/size) static-binds it the next time the workspace is (re)provisioned. The volume is effectively empty, so this is cheap insurance, not a data rescue. |

Every PV is flipped to `reclaimPolicy: Retain` **before** its old PVC is
deleted, so no volume can be destroyed mid-move. `04-cleanup.sh` reverts the
regenerable ones to `Delete`; the Coder-home PV stays `Retain` forever
(your dotfiles have no backup).

## The run (from a machine that survives the window)

Any machine with `kubectl` + `git` + `jq` + `flux` that is **not** a pod
inside `ai`: your laptop, or the `dev` LXC on the NAS. The opencode agent
lives in that LXC and can drive the run itself — it stays alive through the
whole thing, but its LLM is routed through `litellm.ctec.run` → `ai`, so it
is deaf for the length of the Phase B downtime and wakes up again when
`llm` converges (start it with `--yes` in the background; it is self-driving
and idempotent, and writes `window-*.log` next to itself).

> **Warning (already relevant now):** the new template version (default
> namespace `llm`) has already been pushed to Coder while preparing this
> branch. Do **not** run `coder update` (or create workspaces) before
> `02-window.sh` has run: an update before the window makes terraform delete
> the old `ai` home PVC while its PV is still on `reclaimPolicy: Delete`,
> which would destroy your dotfiles/toolchain. The window flips that PV to
> `Retain` first — that is what makes the post-window update safe.

```fish
# 0. prepare (any time before the window; a few minutes)
git fetch origin && git checkout rename-ai-to-llm
./tools/rename-ai-to-llm/01-preflight.sh

# 1. the window (one script; asks you to type `llm` before the destructive half)
./tools/rename-ai-to-llm/02-window.sh          # add --yes for hands-off

# 2. only if you are continuing with Coder: move the workspace onto the new
#    template version (namespace llm). NOT plain `coder start` — that would
#    run the old version, which still targets the deleted `ai` namespace.
#    (Its home volume holds ~16K of IDE scaffolding only. If you are
#    dropping the Coder path, skip this — the PV stays on Retain until
#    deleted.)
coder update <name>

# 3. prove it worked (read-only)
./tools/rename-ai-to-llm/03-verify.sh

# 4. when you've actually used the services and everything is fine:
./tools/rename-ai-to-llm/04-cleanup.sh
```

### Timeline and durations

- **Phase A (no downtime)**: create `llm`, copy the kopiur credentials, apply
  the 5 one-shot Restores, wait for `Populated` from a real snapshot
  (`resolution: Snapshot` — the script refuses to continue on
  `NoSnapshotContinue`, i.e. a silently empty volume). 5–60 min depending on
  how much data changed since the last hourly snapshot (usually minutes).
- **Pause**: the script stops and asks you to type `llm`. The cluster is
  still 100% up; you can take a breather here.
- **Phase B (downtime, ~5–15 min)**: suspend the `ai` KSs → rebind the 4 PVs
  (the owning deployments of the pods mounting them are scaled to 0 —
  deleting a pod alone is not enough: its controller respawns it and the
  `pvc-protection` finalizer would hang the deletion forever; for the Coder
  workspace pod, run `coder stop <workspace>` *before* the window so Coder
  ends in a clean Stopped state, **including the agent's workspace pod**) →
  push the branch to `main` → `cluster-apps` prunes the `ai` KSs (their
  finalizers delete the `ai` Helm releases; the `ai` Namespace itself is
  `prune: disabled` and survives until step 4) → applies the `llm` tree →
  waits for every `llm` KS/HR to be Ready. (The Talos machine-config patch is
  deliberately NOT part of the window — you apply it later with `topf apply`,
  together with the k8s 1.37.2 bump.)
- **After**: if you continue with Coder, `coder update <name>` moves the
  workspace to the new template version (namespace `llm`) and its home PVC
  static-binds the retained PV. If you drop the Coder path, skip it — the PV
  just sits on `Retain` until deleted. Verify, then clean up when satisfied.

### Why the order is safe

1. Data is secured **before** anything is deleted: kopiur copies run while
   `ai` is fully live; rebinds happen only after a `Retain` is in place.
2. The `ai` Kustomizations are **suspended** before any `ai` PVC is deleted,
   so nothing can re-apply/prune a half-moved claim.
3. When the push lands, Flux v2 deletes the 13 `ai` Kustomizations
   (they live in their own namespace); their finalizers prune the `ai`
   inventory (Helm releases, deployments, CRs). Cluster-scoped CRDs carry
   `helm.sh/resource-policy: keep` (or are Helm-installed) and survive; the
   `llm` charts re-install them. The `nas` ClusterRepository is
   cluster-scoped and untouched.
4. The 5 new `llm` PVCs already exist and are Bound when the `llm` KSs land,
   so the components' Restores (same names, now same-namespace sources)
   complete as no-ops; hourly snapshots resume under the new
   `<app>@llm:/pvc/<app>` identities.
5. Litellm's Postgres (and with it the virtual keys for karakeep/mealie/…)
   is part of the kopiur restore, so cross-namespace consumers keep working
   the moment the proxy is up in `llm`.

## Rollback

There is no automatic rollback, but the window is designed to be
re-rollable for most of its duration:

- **Before the `git push` (Phase B step B3)**: nothing in `ai` is lost.
  Delete the objects in `llm` (`kubectl delete ns llm`) and the cluster is
  back where it started, except the 4 rebound PVs still point at `llm`
  claims — repoint them the other way with
  `kubectl patch pv <pv> -p '{"spec":{"claimRef":{"namespace":"ai","name":"<name>"}}}'`
  and re-create the `ai` PVCs (the scripts log every PV name in
  `window-*.log`).
- **After the push, before `04-cleanup.sh`**: `git push origin main~1:main`
  re-lands the old tree; Flux restores the `ai` apps. The 5 kopiur volumes
  come back from their still-intact `ai` policy snapshots; the 4 rebound PVs
  need repointing as above. The `llm` namespace then sits empty until pruned.
- **After `04-cleanup.sh`**: the old `ai` PVCs/volumes are gone. Recovery is
  from the kopiur `nas` snapshots (still the `@ai` identities) for the 5
  kopanur-backed apps — and from nothing for the Coder-home volume if it was
  ever deleted (it is on `Retain`, which is the last line of defence).

## Follow-ups (separate commits, after the rename is proven)

1. Delete this directory.
2. Revert the `opencode` Service `forceRename: opencode-svc` workaround
   (and its HTTPRoute `backendRef`) in one commit — the `opencode.ai`
   collision only existed while the namespace was `ai`.
3. Optional: rename the `postgres-ai` CNPG cluster in `databases`
   (bigger data operation; the `ai` in its name is a false positive for this
   incident, so it is fine to leave).
