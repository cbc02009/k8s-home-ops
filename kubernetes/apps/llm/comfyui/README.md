# ComfyUI

Node-graph image generation UI, running standalone in the `llm` namespace. It is
the second interactive GPU consumer paired with the local LLM stack (`llmkube`,
`qwen3.8-27b`) — the first is `swarmui`, which embeds ComfyUI as its backend.
This app runs upstream ComfyUI directly; only one of the two can hold the GPU
at a time (see "Sharing the GPU with SwarmUI" below).

## GPU pre-emption

`mayne` is the single dGPU worker and exposes exactly one `nvidia.com/gpu`
(never time-sliced), so only one heavy GPU workload can run at a time. The
workloads share the card via Kubernetes `PriorityClass` pre-emption, one-way:

| Workload | PriorityClass | value |
|---|---|---|
| comfyui, swarmui | `gpu-interactive` | `1000` |
| qwen3.8-27b (and other llmkube pods) | `gpu-preemptible` | `-100` |

Because the interactive workloads request the GPU at priority `1000`, scaling
one up makes the scheduler evict the lower-priority LLM pod; scaling it back
down lets the LLM's pending pod rebind to the freed GPU. **You never scale the
LLM stack yourself** — its replicas are owned by the `llmkube-models`
Kustomization (`prune: true`) and the nvidia ModelPool, which would revert any
manual change.

The `gpu-interactive` PriorityClass is defined once, in
`kubernetes/apps/llm/llmkube/app/priorityclass-gpu-interactive.yaml`, and is
cluster-scoped — this app references it, it does not define it.

## Current state

comfyui is committed **parked**:

- `replicas: 0` — consumes nothing, so it can never steal the GPU by accident
- `nvidia.com/gpu: 1` request + limit and `runtimeClassName: nvidia` in place,
  so the *next* time it is scaled up it pre-empts the LLM
- `kubernetes/apps/llm/kustomization.yaml` lists `./comfyui/ks.yaml` (enabled)
- the `comfyui` PVC (10Gi, `ceph-block`) plus backup/restore is supplied by the
  `kopiur` component the Kustomization depends on (its `PVC_CAPACITY`
  substitution in `ks.yaml` sizes the claim; no hand-written pvc.yaml — kopiur
  generates it, and a duplicate would shadow it)

## Per-session workflow

Run `just comfy up` / `just comfy down` from the repo root (the module is
`mod.just` next to this file; `up` blocks until the rollout is Ready, `down`
returns as soon as the scale lands). The raw commands, for reference:

```bash
# 1. stop the Flux Helm controller so it can't revert our manual scale
flux suspend helmrelease comfyui -n llm

# 2. bring comfyui up -> scheduler evicts qwen3.8-27b (-100) for comfyui (1000)
kubectl scale deployment comfyui -n llm --replicas=1
# 2b. optional: block until the ComfyUI pod is Ready
kubectl rollout status deployment comfyui -n llm

# 3. ...generate images... (https://comfyui.ctec.run)

# 4. free the GPU -> 27B's pending pod auto-schedules on the freed GPU
kubectl scale deployment comfyui -n llm --replicas=0

# 5. hand it back to Flux (it stays parked at 0)
flux resume helmrelease comfyui -n llm
```

### Why suspend the HelmRelease, not the Kustomization

The object that owns this Deployment's replica count is the **Flux HelmRelease**
(`comfyui`), reconciled by the Helm controller — that is the object that would
revert a `kubectl scale`. Suspending the `comfyui` **Kustomization** only stops
git → HelmRelease sync and does *not* stop the Helm controller's replica drift
fix, so a suspend there is not enough.

### Sharing the GPU with SwarmUI

`swarmui` uses the same priority class and the same parked-deployment pattern,
so the two cannot hold the GPU simultaneously: whichever scales up second sits
`Pending` (equal priority never pre-empts) until the first is scaled back down.
Bring up one at a time; `kubectl get pods -n llm` shows which one holds the GPU.

## What to expect

- The LLM is down for the whole comfyui session: `qwen3.8-27b` goes down the
  moment comfyui's pod binds, and the pool may also drop `strata-fn` (same GPU).
- On release, the 27B reloads from the shared cache — several minutes. Plan the
  session so you are not ping-ponging the GPU back and forth.

## Data layout

| Mount | Backing | Purpose |
|---|---|---|
| `/app/ComfyUI/user/default` | PVC `comfyui` (subPath `user`) | UI settings, workflows, history |
| `/app/ComfyUI/custom_nodes` | PVC `comfyui` (subPath `custom_nodes`) | custom nodes + their deps |
| `/app/ComfyUI/input` | PVC `comfyui` (subPath `input`) | upload/input files |
| `/app/ComfyUI/output` | NFS `shana:/mnt/smoltank/comfyui/output` | generated images |
| `/app/ComfyUI/models` | NFS `shana:/mnt/smoltank/comfyui/models` | checkpoints, loras, vae, ... |

Model files live on `shana`, not the PVC: they are large, rebuildable and want
to be shared. Create the standard subdirectories on shana before first use
(`checkpoints`, `loras`, `vae`, `upscale_models`, `controlnet`) under
`/mnt/smoltank/comfyui/models`, and place at least one checkpoint there —
ComfyUI shows an empty model list otherwise.

### Ownership

No init container or pod securityContext here, unlike swarmui: the image
entrypoint starts as root, installs any missing custom-node requirements, and
drops to `PUID`/`PGID` (1000/1000), so kubelet-created root-owned `subPath`
directories are writable at startup and end up owned by uid 1000. The NFS
`output`/`models` mounts are *not* chowned:
`/mnt/smoltank/comfyui/{output,models}` on `shana` must be writable by uid 1000.
