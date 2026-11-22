# reasoning-pool — pool rung graph

> ⚠️ **Auto-generated** from `kubernetes/apps/llm/litellm/app/models/reasoning-pool.yaml` — do not hand-edit.
> Regenerate after any change to the pool YAML:
>
> ```bash
> python3 tools/render_pool_rung_graphs.py kubernetes/apps/llm/litellm/app/models/reasoning-pool.yaml
> ```
>
> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.
> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).

## Pool: `reasoning-pool`  (11 rungs)

```
1 glm-5.3-flash(w1) · hy3(w1) · zai-glm-5.3-flash(w1) → 2 deepseek-v4.1-flash(w2) · glm-5.3(w1) · gpt-6-luna(w1) · mimo-v2.6-flash(w2) · minimax-m3.1-flash(w2) → 3 27b → 4 gemini-4-argon(w1) · kimi-k2.7-code
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `glm-5.3-flash` | `opencode_go/glm-5.3-flash` | 1M | 131K | 1 | 2 | 0.150 | 0.500 | 0.0300 |
| 1 | `hy3` | `opencode_go/hy3` | 1.05M | 66K | 1 | 2 | 0.140 | 0.580 | 0.0580 |
| 1 | `zai-glm-5.3-flash` | `zai/glm-5.3-flash` | 1.05M | 131K | 1 | 2 | 0.150 | 0.500 | 0.0300 |
| 2 | `deepseek-v4.1-flash` | `opencode_go/deepseek-v4.1-flash` | 1M | 131K | 2 | 2 | 0.300 | 1.20 | 0.0600 |
| 2 | `glm-5.3` | `opencode_go/glm-5.3` | 1M | 131K | 1 | 2 | 1.40 | 4.40 | 0.260 |
| 2 | `gpt-6-luna` | `opencode_go/gpt-6-luna` | 1.05M | 128K | 1 | 2 | 0.1000 | 0.500 | 0.0100 |
| 2 | `mimo-v2.6-flash` | `opencode_go/mimo-v2.6-flash` | 1.05M | 131K | 2 | 2 | 0.140 | 0.280 | 0.0028 |
| 2 | `minimax-m3.1-flash` | `opencode_go/minimax-m3.1-flash` | 1M | 512K | 2 | 2 | 0.150 | 0.600 | 0.0150 |
| 3 | `27b` | `openai/qwen3.8-27b` | 131K | 41K | - | 2 | 0.0620 | 1.35 | 0.00 |
| 4 | `gemini-4-argon` | `opencode_go/gemini-4-argon` | 1M | 131K | 1 | 1 | 8.00 | 40.00 | 0.400 |
| 4 | `kimi-k2.7-code` | `opencode_go/kimi-k2.7-code` | 262K | 262K | - | 1 | 0.950 | 4.00 | 0.190 |
