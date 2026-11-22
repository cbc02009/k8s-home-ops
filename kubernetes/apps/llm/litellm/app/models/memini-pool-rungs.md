# memini-pool — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/memini-pool.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/memini-pool.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `memini-pool`  (2 rungs)

```
1 deepseek-v4.1-flash(w2) → 2 27b-floor(w1)
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `deepseek-v4.1-flash` | `opencode_go/deepseek-v4.1-flash` | 1M | 131K | 2 | 2 | 0.300 | 1.20 | 0.0600 |
| 2 | `27b-floor` | `openai/qwen3.8-27b` | - | 16K | 1 | 2 | 0.0620 | 1.35 | 0.00 |
