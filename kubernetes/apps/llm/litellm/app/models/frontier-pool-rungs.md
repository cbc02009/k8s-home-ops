# frontier-pool — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/frontier-pool.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/frontier-pool.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `frontier-pool`  (2 rungs)

```
1 qwen3.8-max → 2 kimi-k3.1-pro
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `qwen3.8-max` | `opencode_go/qwen3.8-max` | 1M | 131K | - | 1 | 2.00 | 6.00 | 0.250 |
| 2 | `kimi-k3.1-pro` | `opencode_go/kimi-k3.1-pro` | 1.05M | 131K | - | 1 | 2.00 | 10.00 | 0.200 |
