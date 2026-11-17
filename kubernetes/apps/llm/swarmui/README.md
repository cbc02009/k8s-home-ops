# SwarmUI

ComfyUI frontend for image generation, running in the `llm` namespace. It is the
interactive GPU consumer paired with the local LLM stack (`llmkube`,
`qwen3.8-27b`).

## GPU pre-emption

`mayne` is the single dGPU worker and exposes exactly one `nvidia.com/gpu`
(never time-sliced), so only one heavy GPU workload can run at a time. The two
share the card via Kubernetes `PriorityClass` pre-emption, one-way:

| Workload | PriorityClass | value |
|---|---|---|
| swarmui | `gpu-interactive` | `1000` |
| qwen3.8-27b (and other llmkube pods) | `gpu-preemptible` | `-100` |

Because only swarmui requests the GPU at priority `1000`, scaling it up makes
the scheduler evict the lower-priority LLM pod; scaling it back down lets the
LLM's pending pod rebind to the freed GPU. **You never scale the LLM stack
yourself** — its replicas are owned by the `llmkube-models` Kustomization
(`prune: true`) and the nvidia ModelPool, which would revert any manual change.

## Current state

swarmui is committed **parked**:

- `replicas: 0` — consumes nothing, so it can never steal the GPU by accident
- `nvidia.com/gpu: 1` request + limit and `runtimeClassName: nvidia` in place,
  so the *next* time it is scaled up it pre-empts the LLM
- `kubernetes/apps/llm/kustomization.yaml` lists `./swarmui/ks.yaml` (enabled)
- the `swarmui` PVC (20Gi, `ceph-block`) plus backup/restore is supplied by the
  `kopiur` component the Kustomization depends on

## Per-session workflow

Run `just swarm up` / `just swarm down` from the repo root (the module is
`mod.just` next to this file). The raw commands, for reference:

```bash
# 1. stop the Flux Helm controller so it can't revert our manual scale
flux suspend helmrelease swarmui -n llm

# 2. bring swarmui up -> scheduler evicts qwen3.8-27b (-100) for swarmui (1000)
kubectl scale deployment swarmui -n llm --replicas=1

# 3. ...generate images...

# 4. free the GPU -> 27B's pending pod auto-schedules on the freed GPU
kubectl scale deployment swarmui -n llm --replicas=0

# 5. hand it back to Flux (it stays parked at 0)
flux resume helmrelease swarmui -n llm
```

### Why suspend the HelmRelease, not the Kustomization

The object that owns this Deployment's replica count is the **Flux HelmRelease**
(`swarmui`), reconciled by the Helm controller — that is the object that would
revert a `kubectl scale`. Suspending the `swarmui` **Kustomization** only stops
git → HelmRelease sync and does *not* stop the Helm controller's replica
drift fix, so a suspend there is not enough.

## What to expect

- The LLM is down for the whole swarmui session: `qwen3.8-27b` goes down the
  moment swarmui's pod binds, and the pool may also drop `strata-fn` (same GPU).
- On release, the 27B reloads from the shared cache — several minutes. Plan the
  session so you are not ping-ponging the GPU back and forth.
