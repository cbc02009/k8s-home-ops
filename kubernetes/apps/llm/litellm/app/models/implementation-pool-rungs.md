# implementation-pool — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/implementation-pool.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/implementation-pool.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `implementation-pool`  (6 rungs)

```
1 27b(w2) · glm-flash(w1) · zai-glm-5.3-flash(w1) → 2 mimo-v2.6-flash(w2) → 3 minimax-m3.1-flash(w1) · zai-glm-5.3(w1)
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `27b` | `openai/qwen3.8-27b` | 131K | 41K | 2 | 2 | 0.0620 | 1.35 | 0.00 |
| 1 | `glm-flash` | `opencode_go/glm-5.3-flash` | 1M | 131K | 1 | 2 | 0.150 | 0.500 | 0.0300 |
| 1 | `zai-glm-5.3-flash` | `zai/glm-5.3-flash` | 1.05M | 131K | 1 | 2 | 0.150 | 0.500 | 0.0300 |
| 2 | `mimo-v2.6-flash` | `opencode_go/mimo-v2.6-flash` | 1.05M | 131K | 2 | 2 | 0.140 | 0.280 | 0.0028 |
| 3 | `minimax-m3.1-flash` | `opencode_go/minimax-m3.1-flash` | 1M | 512K | 1 | 2 | 0.150 | 0.600 | 0.0150 |
| 3 | `zai-glm-5.3` | `zai/glm-5.3` | 1.05M | 131K | 1 | 1 | 1.40 | 4.40 | 0.260 |
