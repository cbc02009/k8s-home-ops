# opencode-go — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/opencode-go.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/opencode-go.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `go-pool`  (4 rungs)

```
1 glm-5.3-flash → 2 gpt-6-luna → 3 minimax-m3.1-flash → 4 longcat-2.5-free
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `glm-5.3-flash` | `opencode_go/glm-5.3-flash` | 1M | 131K | - | 4 | 0.150 | 0.500 | 0.0300 |
| 2 | `gpt-6-luna` | `opencode_go/gpt-6-luna` | 1.05M | 128K | - | 4 | 0.1000 | 0.500 | 0.0100 |
| 3 | `minimax-m3.1-flash` | `opencode_go/minimax-m3.1-flash` | 1M | 512K | - | 4 | 0.150 | 0.600 | 0.0150 |
| 4 | `longcat-2.5-free` | `opencode_go/longcat-2.5-free` | 1M | 262K | - | 4 | 0.00 | 0.00 | 0.00 |
