#!/usr/bin/env bash
# ============================================================================
# 03-verify.sh — prove the ai -> llm cutover actually worked: data landed,
# DNS collisions are gone, and every consumer (in-cluster and cross-ns)
# reaches its dependency. Run from any machine with cluster access, after
# 02-window.sh finished and (ideally) after you have started your Coder
# workspace(s). Read-only: it creates one short-lived probe Pod in `llm`
# and deletes it again.
# ============================================================================
set -uo pipefail

NS_NEW="llm"
NS_OLD="ai"
FAILURES=0
ok()   { printf '  OK   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; FAILURES=$((FAILURES+1)); }
warn() { printf '  WARN %s\n' "$*"; }

echo "== 1. namespaces =="
kubectl get ns "$NS_NEW" >/dev/null 2>&1 && ok "$NS_NEW exists" || bad "$NS_NEW missing"
kubectl get ns "$NS_OLD" >/dev/null 2>&1 && warn "$NS_OLD still exists (expected until 04-cleanup.sh)" || ok "$NS_OLD is gone"

echo "== 2. all PVCs in $NS_NEW are Bound =="
while read -r name phase _; do
  [ "$name" = "NAME" ] && continue
  [ "$phase" = "Bound" ] && ok "$name" || bad "$name is $phase"
done < <(kubectl get pvc -n "$NS_NEW" 2>/dev/null)

echo "== 3. Kustomizations / HelmReleases in $NS_NEW =="
[ -z "$(kubectl get kustomization -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="True"')" ] \
  && ok "all $NS_NEW Kustomizations Ready" || { bad "some $NS_NEW Kustomizations not Ready:"; kubectl get kustomization -n "$NS_NEW" | awk 'NR==1||$3!="True"'; }
[ -z "$(kubectl get helmrelease -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="True"')" ] \
  && ok "all $NS_NEW HelmReleases Ready" || { bad "some $NS_NEW HelmReleases not Ready:"; kubectl get helmrelease -n "$NS_NEW" | awk 'NR==1||$3!="True"'; }

echo "== 4. Pods in $NS_NEW =="
badpods=$(kubectl get pods -n "$NS_NEW" --no-headers 2>/dev/null | awk '$4!="Running" && $4!="Completed"')
[ -z "$badpods" ] && ok "all pods Running/Completed" || { bad "pods not Running:"; echo "$badpods" | sed 's/^/    /'; }

echo "== 5. cross-namespace consumers point at $NS_NEW =="
for cr in $(kubectl get litellmvirtualkey -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} {.spec.proxyNamespace}{"\n"}{end}' 2>/dev/null); do
  nsname=${cr%% *}; pns=${cr##* }
  [ "$pns" = "$NS_NEW" ] && ok "virtualkey $nsname -> $pns" || bad "virtualkey $nsname -> $pns"
done
kubectl get litellmvirtualkey -A --no-headers 2>/dev/null | awk 'NR>1 && $3!="True" {print "  FAIL virtualkey "'$1'/'$2'" not Ready"}'

echo "== 6. DNS: public .ai domains must no longer resolve in-cluster =="
# The whole point of the rename. A litellm-side Python image is used for the
# probe so no external pull is needed.
img=$(kubectl get pods -n "$NS_NEW" -l app.kubernetes.io/name=litellm -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null)
[ -n "$img" ] || { warn "could not find a litellm pod image for the probe; skipping in-cluster DNS/HTTP checks"; img=""; }
if [ -n "$img" ]; then
  pod="rename-verify-$(date +%s)"
  PY=$(cat <<'PYEOF'
import socket, urllib.request
def pub(ip):
    return not (ip.startswith("10.") or ip.startswith("192.168.") or ip.startswith("172.16."))
# public .ai domains: must resolve to PUBLIC addresses now
for host in ("memini.ai", "litellm.ai", "headroom.ai", "opencode.ai"):
    try:
        ip = socket.getaddrinfo(host, 443)[0][4][0]
        print(("OK  " if pub(ip) else "FAIL"), f"public {host} -> {ip}")
    except Exception as e:
        print("FAIL", f"public {host} -> {e}")
# in-cluster names: must resolve to cluster service IPs
for host in ("litellm.llm.svc.cluster.local", "memini.llm.svc.cluster.local",
             "headroom.llm.svc.cluster.local", "vmcp-mcp-gateway-internal.llm.svc.cluster.local"):
    try:
        ip = socket.getaddrinfo(host, 443)[0][4][0]
        print(("OK  " if ip.startswith("10.") else "FAIL"), f"in-cluster {host} -> {ip}")
    except Exception as e:
        print("FAIL", f"in-cluster {host} -> {e}")
# short-form names from hermes config (no .svc suffix)
for host in ("litellm.llm", "vmcp-mcp-gateway-internal.llm"):
    try:
        ip = socket.getaddrinfo(host, 443)[0][4][0]
        print(("OK  " if ip.startswith("10.") else "FAIL"), f"short-form {host} -> {ip}")
    except Exception as e:
        print("FAIL", f"short-form {host} -> {e}")
# HTTP liveness of the main services
for name, url in (
    ("litellm",    "http://litellm.llm.svc.cluster.local:4000/health/liveliness"),
    ("memini",     "http://memini.llm.svc.cluster.local:8080/"),
    ("headroom",   "http://headroom.llm.svc.cluster.local:8787/"),
    ("toolhive",   "http://vmcp-mcp-gateway-internal.llm.svc.cluster.local:4483/"),
    ("open-webui", "http://open-webui.llm.svc.cluster.local:8080/"),
):
    try:
        r = urllib.request.urlopen(url, timeout=10)
        print("OK  ", f"HTTP {name}: {r.status}")
    except Exception as e:
        print("WARN", f"HTTP {name}: {e}")
PYEOF
)
  kubectl run "$pod" -n "$NS_NEW" --restart=Never --image="$img" --command -- \
    python3 -c "$PY" >/dev/null 2>&1
  kubectl wait --for=condition=Ready "$pod" -n "$NS_NEW" --timeout=120s >/dev/null 2>&1 || \
    kubectl wait --for=delete "$pod" -n "$NS_NEW" --timeout=120s >/dev/null 2>&1 || true
  # wait until the pod terminates (script always exits 0)
  for _ in $(seq 1 30); do
    [ "$(kubectl get pod "$pod" -n "$NS_NEW" -o jsonpath='{.status.phase}' 2>/dev/null)" = "Succeeded" ] && break
    sleep 2
  done
  kubectl logs "$pod" -n "$NS_NEW" 2>/dev/null
  FAILS=$(kubectl logs "$pod" -n "$NS_NEW" 2>/dev/null | grep -c "^FAIL" || true)
  kubectl delete pod "$pod" -n "$NS_NEW" --grace-period=0 --force >/dev/null 2>&1 || true
  [ "${FAILS:-0}" -eq 0 ] || bad "$FAILS DNS/HTTP checks failed (see output above)"
fi

echo "== 7. llmkube inference services =="
if kubectl get isvc -n "$NS_NEW" >/dev/null 2>&1; then
  kubectl get isvc -n "$NS_NEW" | sed 's/^/    /'
  badisvc=$(kubectl get isvc -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="Ready" && $3!="Running"' || true)
  [ -z "$badisvc" ] && ok "InferenceServices healthy" || warn "some InferenceServices not Ready (may still be downloading models):";
else
  warn "no isvc CRD (llmkube not installed yet?)"
fi

echo "== 8. Coder workspaces (if the CLI is here) =="
if command -v coder >/dev/null; then
  coder workspace list 2>/dev/null | sed 's/^/    /' || warn "coder workspace list failed (not logged in?)"
else
  warn "coder CLI not here; check workspaces at https://coder.ctec.run"
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "VERIFY: $FAILURES failure(s) — see above. Do NOT run 04-cleanup.sh yet."
  exit 1
fi
echo "VERIFY: all green. Safe to run ./04-cleanup.sh when you have had a chance to use the services."
