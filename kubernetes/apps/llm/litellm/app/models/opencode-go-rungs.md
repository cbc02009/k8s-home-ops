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

## Model: `go-chat`  (1 rung)

```
go-chat
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| - | `go-chat` | `opencode_go/claude-haiku-5-5` | 1M | 128K | - | 4 | 0.1000 | 0.500 | 0.0100 |

## Model: `go-coder`  (1 rung)

```
go-coder
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| - | `go-coder` | `opencode_go/kimi-k2.7-code` | 262K | 262K | - | 4 | 0.950 | 4.00 | 0.190 |

## Model: `go-max`  (1 rung)

```
go-max
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| - | `go-max` | `opencode_go/qwen3.8-max` | 1M | 131K | - | 2 | 2.00 | 6.00 | 0.250 |

## Pool: `go-pool`  (10 rungs)

```
1 glm-5.3-flash → 2 mimo-v2.6-flash → 3 gpt-6-luna → 4 minimax-m3.1-flash → 5 qwen3.8-flash → 6 minimax-m3 → 7 kimi-k2.7-code → 8 longcat-2.5-free → 9 beam-free → 10 hy4-flash-free
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `glm-5.3-flash` | `opencode_go/glm-5.3-flash` | 1M | 131K | - | 4 | 0.150 | 0.500 | 0.0300 |
| 2 | `mimo-v2.6-flash` | `opencode_go/mimo-v2.6-flash` | 1.05M | 131K | - | 4 | 0.140 | 0.280 | 0.0028 |
| 3 | `gpt-6-luna` | `opencode_go/gpt-6-luna` | 1.05M | 128K | - | 4 | 0.1000 | 0.500 | 0.0100 |
| 4 | `minimax-m3.1-flash` | `opencode_go/minimax-m3.1-flash` | 1M | 512K | - | 4 | 0.150 | 0.600 | 0.0150 |
| 5 | `qwen3.8-flash` | `opencode_go/qwen3.8-flash` | 1M | 131K | - | 4 | 0.150 | 0.470 | 0.0160 |
| 6 | `minimax-m3` | `opencode_go/minimax-m3` | 1M | 131K | - | 4 | 0.300 | 1.20 | 0.0600 |
| 7 | `kimi-k2.7-code` | `opencode_go/kimi-k2.7-code` | 262K | 262K | - | 4 | 0.950 | 4.00 | 0.190 |
| 8 | `longcat-2.5-free` | `opencode_go/longcat-2.5-free` | 1M | 262K | - | 4 | 0.00 | 0.00 | 0.00 |
| 9 | `beam-free` | `opencode_go/beam-free` | 1.05M | 131K | - | 4 | 0.00 | 0.00 | 0.00 |
| 10 | `hy4-flash-free` | `opencode_go/hy4-flash-free` | 1.05M | 66K | - | 4 | 0.00 | 0.00 | 0.00 |

## Model: `go-strong`  (1 rung)

```
go-strong
```

| Rung | Model | Provider/model | MaxIn | MaxOut | Wt | MP | $/1M in | $/1M out | $/1M cache-read |
|---|---|---|---|---|---|---|---|---|---|
| - | `go-strong` | `opencode_go/kimi-k3.1-pro` | 1.05M | 131K | - | 2 | 2.00 | 10.00 | 0.200 |
