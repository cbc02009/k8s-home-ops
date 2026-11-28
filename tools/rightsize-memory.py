#!/usr/bin/env python3
# yaml-language-server: $schema=none
"""rightsize-memory.py — data-driven memory requests/limits analyzer for the cluster.

Reads live + historical metrics from Prometheus (kube-prometheus-stack) and
produces a per-workload memory rightsizing report:

  - actual usage per (namespace, workload, container) over a window: p95 and max
  - current memory request/limit per replica (0 = scaled down)
  - suggested request = p95 * req-headroom, suggested limit = max * limit-headroom
  - OOM flags (limit was hit at some point in the window)
  - GPU/llmkube-managed and system namespace exclusions
  - cluster + per-node request projection before/after

Verify mode: pass --verify proposals.json (the same JSON --json emits) to
re-check candidate values against the same history: PASS/FAIL per row plus
projected node totals. Nothing in this script mutates the cluster.

Requires only the Python stdlib. Read-only against Prometheus.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.parse
import urllib.request
from collections import defaultdict

DEFAULT_PROM = "http://kube-prometheus-stack-prometheus.observability.svc.cluster.local:9090"

# Per repo AGENTS.md: never touch kube-system or Rook-Ceph without explicit ask.
EXCLUDED_NAMESPACES = {"kube-system", "rook-ceph"}

# llmkube-managed GPU model workloads: their host-memory requests are deliberate
# (model load strategy), not phantom. Editable via --llmkube-workloads.
DEFAULT_LLMKUBE_WORKLOADS = [
    "qwen3.8-27b",
    "embed-1",
    "embed-2",
    "memini-rerank-1",
    "memini-rerank-2",
]

MI = 1024 * 1024
GIB = 1024 * MI


# --------------------------------------------------------------------------
# Prometheus access
# --------------------------------------------------------------------------

def prom_query(base_url: str, query: str, timeout: int = 180):
    """Instant query; returns list of {metric, value:[ts, str]} result items."""
    url = base_url.rstrip("/") + "/api/v1/query?" + urllib.parse.urlencode({"query": query})
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        payload = json.loads(resp.read().decode())
    if payload.get("status") != "success":
        raise RuntimeError(f"Prometheus query failed: {payload}")
    return payload["data"]["result"]


def scalar_from_sample(sample) -> float:
    return float(sample["value"][1])


# --------------------------------------------------------------------------
# Metric collectors (each returns a plain dict keyed by tuples)
# --------------------------------------------------------------------------

def per_pod_metric(base_url: str, query: str) -> dict:
    """Instant query -> {(ns, pod, container): value} for series carrying those labels."""
    out = {}
    for item in prom_query(base_url, query):
        m = item["metric"]
        key = (m.get("namespace", ""), m.get("pod", ""), m.get("container", ""))
        out[key] = scalar_from_sample(item)
    return out


def collect(base_url: str, window: str) -> dict:
    c_filters = '{container!="",container!="POD",image!=""}'
    data = {}
    data["requests"] = per_pod_metric(
        base_url, f'kube_pod_container_resource_requests{{resource="memory",unit="byte"}}'
    )
    data["limits"] = per_pod_metric(
        base_url, f'kube_pod_container_resource_limits{{resource="memory",unit="byte"}}'
    )
    data["usage_max"] = per_pod_metric(
        base_url, f"max by (namespace, pod, container) (max_over_time(container_memory_working_set_bytes{c_filters}[{window}]))"
    )
    data["usage_p95"] = per_pod_metric(
        base_url, f"max by (namespace, pod, container) (quantile_over_time(0.95, container_memory_working_set_bytes{c_filters}[{window}]))"
    )
    data["oom"] = per_pod_metric(
        base_url, f"max by (namespace, pod, container) (max_over_time(kube_pod_container_status_last_terminated_reason{{reason=\"OOMKilled\"}}[{window}]))"
    )
    data["gpu"] = per_pod_metric(
        base_url, 'kube_pod_container_resource_requests{resource=~"nvidia.com/gpu|amd.com/gpu|gpu"}'
    )

    # pod -> owner
    pod_owner = {}
    for item in prom_query(base_url, "kube_pod_owner"):
        m = item["metric"]
        pod_owner[(m["namespace"], m["pod"])] = (m.get("owner_kind", ""), m.get("owner_name", ""))
    data["pod_owner"] = pod_owner

    # replicaset -> deployment
    rs_owner = {}
    for item in prom_query(base_url, "kube_replicaset_owner"):
        m = item["metric"]
        rs_owner[(m["namespace"], m.get("replicaset", ""))] = (
            m.get("owner_kind", ""),
            m.get("owner_name", ""),
        )
    data["rs_owner"] = rs_owner

    # pod -> node
    pod_node = {}
    for item in prom_query(base_url, "kube_pod_info"):
        m = item["metric"]
        node = m.get("node", "")
        if node:
            pod_node[(m["namespace"], m["pod"])] = node
    data["pod_node"] = pod_node

    # node allocatable memory
    alloc = {}
    for item in prom_query(base_url, 'kube_node_status_allocatable{resource="memory",unit="byte"}'):
        alloc[item["metric"]["node"]] = scalar_from_sample(item)
    data["allocatable"] = alloc

    # HPAs gated at min=0 (zeroscaler pattern): HPA name ~= deployment name
    hpa_min0 = set()
    for item in prom_query(base_url, "kube_horizontalpodautoscaler_spec_min_replicas"):
        if scalar_from_sample(item) == 0:
            m = item["metric"]
            hpa_min0.add((m["namespace"], m.get("horizontalpodautoscaler", "")))
    data["hpa_min0"] = hpa_min0

    return data


# --------------------------------------------------------------------------
# Workload identity + aggregation
# --------------------------------------------------------------------------

def resolve_workload(data: dict, ns: str, pod: str):
    """Map a pod to (kind, workload_name)."""
    kind, name = data["pod_owner"].get((ns, pod), ("Pod", pod))
    if kind == "ReplicaSet":
        kind, name = data["rs_owner"].get((ns, name), ("ReplicaSet", name))
    if not name:
        kind, name = "Pod", pod
    return kind, name


def strip_pod_candidates(pod: str) -> list[str]:
    """Possible workload names for a dead pod (Deployment RS and StatefulSet naming)."""
    seg = pod.split("-")
    out = []
    if len(seg) > 2:
        out.append("-".join(seg[:-2]))  # <deploy>-<rs-hash>-<suffix>
    if len(seg) > 1:
        out.append("-".join(seg[:-1]))  # <sts>-<ordinal>
    return out


def round_up_memory(b: float) -> int:
    """Round up to scheduler-friendly chunks."""
    if b <= 128 * MI:
        step = 64 * MI
    elif b <= 1 * GIB:
        step = 128 * MI
    elif b <= 4 * GIB:
        step = 256 * MI
    else:
        step = 512 * MI
    return int((b + step - 1) // step * step)


def humanize(b: float) -> str:
    if b is None:
        return "—"
    if b >= GIB:
        return f"{b / GIB:.1f}Gi"
    return f"{int(round(b / MI))}Mi"


def aggregate(data: dict, window: str) -> list:
    """Group per-pod metrics into per-(ns, workload, container) rows.

    Only live pods (present in kube_pod_owner) contribute to sizing; dead pods
    from the window would fragment into thousands of rows. Their OOM events are
    still harvested and folded into the matching live workload (best-effort
    name-based attribution) so recently-crashed replicas keep their caution flag.
    """
    live = lambda ns, pod: (ns, pod) in data["pod_owner"]
    pods_by_key = defaultdict(set)
    for (ns, pod, container) in set(data["requests"]) | set(data["usage_max"]):
        if not live(ns, pod):
            continue
        kind, wl = resolve_workload(data, ns, pod)
        pods_by_key[(ns, kind, wl, container)].add(pod)

    # Harvest OOM events from dead pods onto live workloads (caution only).
    live_wl_names = {(ns, wl) for (ns, _k, wl, _c) in pods_by_key}
    dead_oom = defaultdict(set)  # (ns, wl, container) -> set of dead pods
    for (ns, pod, container), v in data["oom"].items():
        if v <= 0 or live(ns, pod):
            continue
        for stripped in strip_pod_candidates(pod):
            if (ns, stripped) in live_wl_names:
                dead_oom[(ns, stripped, container)].add(pod)
                break

    rows = []
    for (ns, kind, wl, container), pods in sorted(pods_by_key.items()):
        reqs: list[float] = []
        lims: list[float] = []
        p95s: list[float] = []
        maxs: list[float] = []
        for p in pods:
            k = (ns, p, container)
            if k in data["requests"]:
                reqs.append(data["requests"][k])
            if k in data["limits"]:
                lims.append(data["limits"][k])
            if k in data["usage_p95"]:
                p95s.append(data["usage_p95"][k])
            if k in data["usage_max"]:
                maxs.append(data["usage_max"][k])
        if not p95s and not maxs:
            continue  # never ran in the window; no data to size from

        row = {
            "namespace": ns,
            "kind": kind,
            "workload": wl,
            "container": container,
            "replicas": len(pods),
            "request": max(reqs) if reqs else 0.0,   # per-replica; 0 == scaled down
            "limit": max(lims) if lims else 0.0,     # per-replica; 0 == unlimited/unset
            "p95": max(p95s) if p95s else 0.0,       # conservative across replicas
            "max": max(maxs) if maxs else 0.0,
            "oom": any((ns, p, container) in data["oom"] and data["oom"][(ns, p, container)] > 0
                       for p in pods) or (ns, wl, container) in dead_oom,
            "gpu": any((ns, p, container) in data["gpu"] for p in pods),
            "zeroscaler": (ns, wl) in data["hpa_min0"],
            "nodes": sorted({data["pod_node"][(ns, p)] for p in pods if (ns, p) in data["pod_node"]}),
            "pod_nodes": {p: data["pod_node"][(ns, p)] for p in pods if (ns, p) in data["pod_node"]},
        }
        rows.append(row)
    return rows


def classify(row: dict, args) -> tuple[str, str]:
    """Return (status, reason) governing whether we suggest new values."""
    if row["namespace"] in EXCLUDED_NAMESPACES:
        return "excluded", f"namespace {row['namespace']} is out of scope"
    if row["gpu"]:
        return "excluded", "requests GPU (llmkube-managed model workload)"
    if row["workload"] in args.llmkube_workloads:
        return "excluded", "llmkube-managed model workload (deliberate sizing)"
    if row["p95"] <= 0 and row["max"] <= 0:
        return "nodata", "no usage samples in window"
    if row["oom"]:
        return "caution", "OOM in window — shrink only after checking cause"
    return "ok", ""


def suggest(row: dict, args) -> dict:
    p95 = row["p95"]
    peak = row["max"]
    # request: cover p95 with headroom; but never below what was actually seen
    # as sustained baseline (p95) — and never above current unless under-sized.
    req = max(p95 * args.req_headroom, min(p95, peak) * 1.1)
    lim = max(peak * args.limit_headroom, req * 1.1)
    if row["oom"]:
        # don't shrink below current if the limit was recently hit
        lim = max(lim, row["limit"])
        req = max(req, min(row["request"], req * 1.5)) if row["request"] else req
    floor = args.floor_mib * MI
    return {
        "request": max(round_up_memory(req), floor),
        "limit": max(round_up_memory(lim), round_up_memory(max(req, floor))),
    }


# --------------------------------------------------------------------------
# Report rendering
# --------------------------------------------------------------------------

def build_report(rows: list, data: dict, args) -> tuple[str, list]:
    now_req = sum(r["request"] * r["replicas"] for r in rows)
    now_lim = sum(r["limit"] * r["replicas"] for r in rows if r["limit"] > 0)
    sug_req = sum(s["request"] * r["replicas"] for r, s in ((r, r["_sug"]) for r in rows))
    sug_lim = sum(s["limit"] * r["replicas"] for r, s in ((r, r["_sug"]) for r in rows) if s["limit"] > 0)

    lines = []
    lines.append(f"# Memory rightsizing report")
    lines.append("")
    lines.append(f"window: {args.window}  req-headroom: {args.req_headroom}  limit-headroom: {args.limit_headroom}")
    lines.append("")
    total_alloc = sum(data["allocatable"].values())
    lines.append("## Cluster summary (scopable workloads)")
    lines.append("")
    lines.append(f"node allocatable total: {humanize(total_alloc)}")
    lines.append(f"requests now: {humanize(now_req)}  ->  suggested: {humanize(sug_req)}")
    lines.append(f"limits now: {humanize(now_lim)}  ->  suggested: {humanize(sug_lim)}")
    lines.append(f"limits overcommit now: {now_lim / total_alloc:.2f}x  ->  suggested: {sug_lim / total_alloc:.2f}x")
    lines.append(f"request fill now: {now_req / total_alloc * 100:.0f}%  ->  suggested: {sug_req / total_alloc * 100:.0f}%")
    lines.append("")

    # per-node projection using CURRENT pod placement
    lines.append("## Per-node request projection (current placement)")
    lines.append("")
    node_now = defaultdict(float)
    node_sug = defaultdict(float)
    for r in rows:
        for pod, node in r["pod_nodes"].items():
            node_now[node] += r["request"]
            node_sug[node] += r["_sug"]["request"]
    for node in sorted(set(node_now) | set(node_sug)):
        alloc = data["allocatable"].get(node, 0)
        lines.append(
            f"{node}: now {humanize(node_now[node])} / {humanize(alloc)}"
            f" ({node_now[node] / alloc * 100:.0f}%)  ->  suggested {humanize(node_sug[node])}"
            f" ({node_sug[node] / alloc * 100:.0f}%)"
        )
    lines.append("")

    lines.append("## Per-workload detail (sorted by request savings)")
    lines.append("")
    shown = [r for r in rows if args.show_excluded or r["_status"][0] in ("ok", "caution")]
    shown_ids = {id(r) for r in shown}
    omitted = defaultdict(int)
    for r in rows:
        if id(r) not in shown_ids:
            omitted[r["_status"][0]] += 1
    if omitted:
        lines.append(
            f"({sum(omitted.values())} rows omitted: "
            + ", ".join(f"{k}={v}" for k, v in sorted(omitted.items()))
            + " — use --show-excluded to list)"
        )
        lines.append("")
    lines.append(
        "| ns | workload | container | repl | req now | limit now | p95 | max | OOM | flags | sug req | sug limit | dReq |"
    )
    lines.append("|---|---|---|---:|---:|---:|---:|---:|---|---|---:|---:|---:|")
    for r in shown:
        flags = []
        st, reason = r["_status"]
        if st != "ok":
            flags.append(st)
        if r["zeroscaler"]:
            flags.append("zeroscaler(hpa-min0)")
        if r["request"] == 0:
            flags.append("no-request")
        if r["limit"] == 0:
            flags.append("no-limit")
        if r["p95"] > r["request"] > 0:
            flags.append("under-requested")
        dreq = (r["_sug"]["request"] - r["request"]) * r["replicas"]
        oom = "YES" if r["oom"] else ""
        lines.append(
            f"| {r['namespace']} | {r['kind']}/{r['workload']} | {r['container']} "
            f"| {r['replicas']} | {humanize(r['request'])} | {humanize(r['limit'])} "
            f"| {humanize(r['p95'])} | {humanize(r['max'])} | {oom} "
            f"| {','.join(flags)} | {humanize(r['_sug']['request'])} "
            f"| {humanize(r['_sug']['limit'])} | {humanize(dreq)} |"
        )
    lines.append("")
    # reasons footnotes
    seen = {}
    for r in rows:
        st, reason = r["_status"]
        if reason:
            seen.setdefault(st, reason)
    if seen:
        lines.append("Notes: " + "; ".join(f"**{k}** = {v}" for k, v in sorted(seen.items())))
        lines.append("")
    return "\n".join(lines), rows


def json_output(rows: list) -> str:
    out = [
        {
            "namespace": r["namespace"],
            "workload": r["workload"],
            "container": r["container"],
            "request_mib": int(r["_sug"]["request"] // MI),
            "limit_mib": int(r["_sug"]["limit"] // MI),
        }
        for r in rows
        if r["_status"][0] in ("ok", "caution")
    ]
    return json.dumps(out, indent=2)


# --------------------------------------------------------------------------
# Verify mode
# --------------------------------------------------------------------------

def verify(base_url: str, proposals_path: str, args) -> int:
    with open(proposals_path) as fh:
        proposals = json.load(fh)
    data = collect(base_url, args.window)
    rows = aggregate(data, args.window)
    by_key = {(r["namespace"], r["workload"], r["container"]): r for r in rows}

    failures = 0
    print(f"verify: {len(proposals)} proposals against {args.window} window")
    print("")
    print("| ns | workload | container | prop req | prop lim | p95 | max | OOM | verdict |")
    print("|---|---|---|---:|---:|---:|---:|---|---|")
    for p in proposals:
        key = (p["namespace"], p["workload"], p["container"])
        r = by_key.get(key)
        if r is None:
            print(f"| {p['namespace']} | {p['workload']} | {p['container']} | — | — | — | — | — | **NO DATA** |")
            failures += 1
            continue
        preq = p["request_mib"] * MI
        plim = p["limit_mib"] * MI
        checks = []
        if r["p95"] * args.req_headroom > preq:
            checks.append(f"req<{humanize(r['p95'])}x{args.req_headroom}")
        if plim < r["max"]:
            checks.append(f"lim<{humanize(r['max'])}")
        if r["oom"]:
            checks.append("OOM-in-window")
        if checks:
            verdict = "FAIL: " + ",".join(checks)
            failures += 1
        else:
            verdict = "PASS"
        print(
            f"| {r['namespace']} | {r['workload']} | {r['container']} "
            f"| {humanize(preq)} | {humanize(plim)} | {humanize(r['p95'])} "
            f"| {humanize(r['max'])} | {'YES' if r['oom'] else ''} | **{verdict}** |"
        )
    print("")
    print(f"{len(proposals) - failures}/{len(proposals)} PASS")
    return 1 if failures else 0


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[0])
    ap.add_argument("--prometheus-url", default=DEFAULT_PROM)
    ap.add_argument("--window", default="14d", help="analysis window (PromQL duration, default 14d)")
    ap.add_argument("--req-headroom", type=float, default=1.3)
    ap.add_argument("--limit-headroom", type=float, default=1.4)
    ap.add_argument("--floor-mib", type=int, default=128, help="minimum suggested request (MiB)")
    ap.add_argument("--llmkube-workloads", nargs="*", default=DEFAULT_LLMKUBE_WORKLOADS)
    ap.add_argument("--json", action="store_true", dest="as_json", help="emit machine-readable proposals")
    ap.add_argument("--show-excluded", action="store_true", help="include excluded/nodata rows in the table")
    ap.add_argument("--verify", metavar="FILE", help="verify proposals JSON instead of reporting")
    args = ap.parse_args()

    if args.verify:
        return verify(args.prometheus_url, args.verify, args)

    data = collect(args.prometheus_url, args.window)
    rows = aggregate(data, args.window)
    for r in rows:
        r["_status"] = classify(r, args)
        r["_sug"] = suggest(r, args) if r["_status"][0] in ("ok", "caution") else {
            "request": r["request"], "limit": r["limit"]
        }
    rows.sort(key=lambda r: (r["_sug"]["request"] - r["request"]) * r["replicas"])

    if args.as_json:
        print(json_output(rows))
    else:
        report, _ = build_report(rows, data, args)
        print(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
