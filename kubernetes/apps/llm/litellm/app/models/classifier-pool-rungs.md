# classifier-pool — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/classifier-pool.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/classifier-pool.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `classifier-pool`  (3 rungs)

```
1 beam-free(w3) · hy4-flash-free(w3) → 2 27b-floor(w1)
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `beam-free` | `opencode_go/beam-free` | 1.05M | 131K | 3 | 4 | 0.00 | 0.00 | 0.00 |
| 1 | `hy4-flash-free` | `opencode_go/hy4-flash-free` | 1.05M | 66K | 3 | 4 | 0.00 | 0.00 | 0.00 |
| 2 | `27b-floor` | `openai/qwen3.8-27b` | - | 16K | 1 | 2 | 0.0620 | 1.35 | 0.00 |
