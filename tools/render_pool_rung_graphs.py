#!/usr/bin/env python3
"""Render a per-pool "rung graph" as a markdown file next to a LiteLLM pool YAML.

Each `LiteLLMModel` CR in a pool file is one RUNG in a fallback ladder. Rungs
are tried in ascending `spec.params.additional.order` (lower = first). This
script turns a pool YAML into a sibling `<base>-rungs.md` (e.g.
`opencode-go.yaml` -> `opencode-go-rungs.md`) that shows the ladder as a
graph (rung-1 -> rung-2 -> ...) plus a data table (model, context window,
$ / 1M tokens in/out, cache-read, and burn weight where present).

The .md is DERIVED from the YAML. It is required to be regenerated whenever
the pool YAML changes. Regenerate with:

    python3 tools/render_pool_rung_graphs.py \
        kubernetes/apps/llm/litellm/app/models/opencode-go.yaml \
        kubernetes/apps/llm/litellm/app/models/reasoning-pool.yaml

and re-run `pre-commit run --files <changed>` + `flate test all` before
committing (see AGENTS.md). CI can enforce sync by re-running this tool and
failing on `git diff --exit-code`.

Pool identity heuristic: a CR named `<p1>-<p2>-<model...>` belongs to the
two-token pool `<p1>-<p2>` (e.g. `go-pool-glm-5.3-flash` -> pool `go-pool`,
model `glm-5.3-flash`). A two-token name (`go-coder`, `go-max`) is its own
standalone single-model pool. POOL_TOKENS changes the prefix depth if a
pool is ever named with more tokens.

Stays read-only on the source YAML; only writes the .md sibling.
"""
import argparse
import pathlib

from ruamel.yaml import YAML

yaml = YAML(typ="safe")
POOL_TOKENS = 2


def humanize_tokens(n):
    """1048576 -> '1.05M', 262144 -> '262K', 131072 -> '131K'."""
    if n is None:
        return "-"
    n = int(n)
    if n >= 1_000_000:
        s = f"{n / 1_000_000:.2f}".rstrip("0").rstrip(".")
        return f"{s or '1'}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}K"
    return str(n)


def cost_per_million(tok):
    """cost-per-token -> $ / 1M tokens, formatted to 4 sig figs."""
    if tok is None:
        return "-"
    v = float(tok) * 1_000_000
    if v == 0:
        return "0.00"
    if v < 0.1:
        return f"{v:.4f}"
    if v < 1:
        return f"{v:.3f}"
    return f"{v:.2f}"


def pool_key(cr_name):
    """Split a CR name into (pool, model). Two-token names are standalone."""
    toks = cr_name.split("-")
    if len(toks) > POOL_TOKENS:
        return "-".join(toks[:POOL_TOKENS]), "-".join(toks[POOL_TOKENS:])
    return cr_name, ""


def rung_number(additional):
    return additional.get("order")


def load_pool(path):
    docs = [d for d in yaml.load_all(open(path)) if d]
    pools = {}
    for d in docs:
        meta = d.get("metadata", {}) or {}
        name = meta.get("name", "?")
        spec = d.get("spec", {}) or {}
        params = spec.get("params", {}) or {}
        info = spec.get("info", {}) or {}
        additional = params.get("additional", {}) or {}
        extra = info.get("extra", {}) or {}
        pool, model = pool_key(name)
        row = {
            "order": rung_number(additional),
            "name": name,
            "model": model,
            "full": params.get("model", ""),
            "weight": additional.get("weight"),
            "mp": additional.get("max_parallel_requests"),
            "maxin": info.get("maxInputTokens"),
            "maxout": info.get("maxOutputTokens"),
            "in": extra.get("input_cost_per_token"),
            "out": extra.get("output_cost_per_token"),
            "cache": extra.get("cache_read_input_token_cost"),
        }
        pools.setdefault(pool, []).append(row)
    for rows in pools.values():
        rows.sort(key=lambda r: (r["order"] is None, r["order"] if r["order"] is not None else 0, r["name"]))
    return pools


def graph_line(rows):
    """Collapse rows into one node per rung (a rung may hold several weighted models)."""
    groups = {}
    seq = []
    for r in rows:  # already sorted
        o = r["order"]
        if o not in groups:
            groups[o] = []
            seq.append(o)
        groups[o].append(r)
    parts = []
    for o in seq:
        models = []
        for r in groups[o]:
            label = r["model"] or r["name"]
            models.append(f"{label}(w{r['weight']})" if r["weight"] is not None else label)
        head = f"{o} " if o is not None else ""
        parts.append(head + " · ".join(models))
    return " → ".join(parts)


def render(pools, base_name, src_rel):
    out = []
    out.append(f"# {base_name} — pool rung graph")
    out.append("")
    out.append(f"> ⚠️ **Auto-generated** from `{src_rel}` — do not hand-edit.")
    out.append("> Regenerate after any change to the pool YAML:")
    out.append(">")
    out.append(f"> ```bash\n> python3 tools/render_pool_rung_graphs.py {src_rel}\n> ```")
    out.append(">")
    out.append("> Rungs are tried in ascending `order` (first rung is the primary) and fall back down the ladder. A rung can hold several weighted models; `weight` divides the pool's shared burn budget (Go Plus). `MP` = max_parallel_requests.")
    out.append("> **This file must be regenerated whenever the pool YAML changes.** Do not hand-edit; re-run the command above and re-validate (pre-commit + flate).")
    out.append("")

    for pool in sorted(pools):
        rows = pools[pool]
        # a single-model entry with no ladder order is a named alias, not a pool
        standalone = len(rows) == 1 and rows[0]["order"] is None
        kind = "Model" if standalone else "Pool"
        out.append(f"## {kind}: `{pool}`  ({len(rows)} rung{'s' if len(rows) != 1 else ''})")
        out.append("")
        out.append("```")
        out.append(graph_line(rows))
        out.append("```")
        out.append("")
        hdr = ["Rung", "Model", "Provider/model", "MaxIn", "MaxOut",
               "Wt", "MP", "$/1M in", "$/1M out", "$/1M cache-read"]
        out.append("| " + " | ".join(hdr) + " |")
        out.append("|" + "---|" * len(hdr))
        for r in rows:
            o = "-" if r["order"] is None else r["order"]
            w = "-" if r["weight"] is None else r["weight"]
            mp = "-" if r["mp"] is None else r["mp"]
            cells = [
                str(o),
                f"`{r['model'] or r['name']}`",
                f"`{r['full']}`",
                humanize_tokens(r["maxin"]),
                humanize_tokens(r["maxout"]),
                str(w),
                str(mp),
                cost_per_million(r["in"]),
                cost_per_million(r["out"]),
                cost_per_million(r["cache"]),
            ]
            out.append("| " + " | ".join(cells) + " |")
        out.append("")
    # normalize: ensure trailing newline, no double blank lines, no trailing ws
    text = "\n".join(out)
    lines = [ln.rstrip() for ln in text.split("\n")]
    # collapse >1 consecutive blank lines
    cleaned = []
    prev_blank = False
    for ln in lines:
        if ln == "":
            if prev_blank:
                continue
            prev_blank = True
        else:
            prev_blank = False
        cleaned.append(ln)
    while cleaned and cleaned[-1] == "":
        cleaned.pop()
    return "\n".join(cleaned) + "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="+", help="pool YAML file(s); a sibling <base>-rungs.md is written for each")
    args = ap.parse_args()
    for f in args.files:
        p = pathlib.Path(f)
        if not p.exists():
            print(f"missing: {p}", file=__import__("sys").stderr)
            continue
        pools = load_pool(p)
        out_path = p.with_name(p.stem + "-rungs.md")
        text = render(pools, p.stem, str(p))
        out_path.write_text(text, encoding="utf-8")
        print(f"wrote {out_path} ({sum(len(v) for v in pools.values())} rungs, {len(pools)} pools)")


if __name__ == "__main__":
    main()
