# zai-pool — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/zai-pool.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/zai-pool.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `zai-pool`  (2 rungs)

```
1 glm-5.3-flash(w2) → 2 glm-5.3(w1)
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `glm-5.3-flash` | `zai/glm-5.3-flash` | 1.05M | 131K | 2 | 2 | 0.150 | 0.500 | 0.0300 |
| 2 | `glm-5.3` | `zai/glm-5.3` | 1.05M | 131K | 1 | 1 | 1.40 | 4.40 | 0.260 |
