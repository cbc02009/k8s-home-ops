#!/usr/bin/env bash
# ============================================================================
# 01-preflight.sh — run this RIGHT BEFORE the window (and once now, ahead of
# time). Exits non-zero if anything is not ready, so it is safe to gate the
# window on it. Safe to run from any machine with cluster access; the flate
# checks need a checkout of branch `rename-ai-to-llm`.
# ============================================================================
set -uo pipefail

NS_OLD="ai"
NS_NEW="llm"
BRANCH="rename-ai-to-llm"
KOPAN_APPS=(hermes litellm memini opencode open-webui)
FAILURES=0
ok()   { printf '  OK   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; FAILURES=$((FAILURES+1)); }
warn() { printf '  WARN %s\n' "$*"; }

echo "== 1. repository state =="
REPO="$(git rev-parse --show-toplevel 2>/dev/null)" || { bad "not in a git checkout"; REPO=""; }
if [ -n "$REPO" ]; then
  [ "$(git -C "$REPO" branch --show-current)" = "$BRANCH" ] \
    && ok "on branch $BRANCH" || bad "on branch '$(git -C "$REPO" branch --show-current)' — checkout $BRANCH"
  git -C "$REPO" fetch origin "$BRANCH" --quiet 2>/dev/null \
    && { [ "$(git -C "$REPO" rev-parse HEAD)" = "$(git -C "$REPO" rev-parse origin/$BRANCH)" ] \
          && ok "local HEAD == origin/$BRANCH" || bad "local HEAD differs from origin/$BRANCH (git pull)"; } \
    || warn "could not fetch origin/$BRANCH"
fi

echo "== 2. cluster reachable =="
kubectl get ns >/dev/null 2>&1 && ok "api server reachable" || bad "api server not reachable"

echo "== 3. kopiur snapshot freshness (the restore source) =="
for app in "${KOPAN_APPS[@]}"; do
  ts=$(kubectl get snapshotpolicy -n "$NS_OLD" "$app" -o jsonpath='{.status.lastSuccessfulSnapshot}' 2>/dev/null || true)
  if [ -z "$ts" ]; then
    bad "$app: no lastSuccessfulSnapshot on the $NS_OLD policy (kopiur problem? kubectl get snapshotpolicy -n $NS_OLD)"
    continue
  fi
  age_h=$(( ( $(date +%s) - $(date -d "${ts%%.*}" +%s) ) / 3600 ))
  if [ "$age_h" -le 3 ]; then
    ok "$app: last snapshot ${age_h}h ago"
  else
    bad "$app: last snapshot ${age_h}h ago (>3h) — wait for the hourly schedule or check kopiur (kubectl get snapshotschedule -n $NS_OLD)"
  fi
done

echo "== 4. PVCs in $NS_OLD (baseline before the window) =="
kubectl get pvc -n "$NS_OLD" 2>/dev/null | tee /dev/stderr | awk 'NR>1' | while read -r name phase _; do
  [ "$phase" = "Bound" ] || echo "  FAIL $name is $phase"
done
[ "$(kubectl get pvc -n "$NS_OLD" --no-headers 2>/dev/null | awk '$3!="Bound"' | wc -l)" -eq 0 ] \
  && ok "all $NS_OLD PVCs Bound" || bad "some $NS_OLD PVCs are not Bound"

echo "== 5. static-binding ambiguity for the Coder home volume =="
# The Coder terraform PVC (10Gi RWO ceph-filesystem, no volumeName) will bind
# by matching an Available PV. If another identical Available PV exists the
# match could be ambiguous.
amb=$(kubectl get pv -o json 2>/dev/null | jq -r '
  [.items[] | select(.status.phase=="Available"
    and .spec.storageClassName=="ceph-filesystem"
    and (.spec.accessModes|index("ReadWriteOnce"))
    and .spec.capacity.storage=="10Gi"] | .metadata.name' 2>/dev/null | grep -v "pvc-4a16f6d7" || true)
[ -z "$amb" ] && ok "no competing Available 10Gi RWO ceph-filesystem PVs" \
  || warn "extra Available 10Gi RWO ceph-filesystem PVs: $amb (the Coder PVC could bind the wrong one — delete them or set volumeName in the template before the window)"

echo "== 6. target namespace =="
kubectl get ns "$NS_NEW" >/dev/null 2>&1 && warn "$NS_NEW already exists (the window script will adopt it)" \
  || ok "$NS_NEW does not exist yet (window script creates it)"

echo "== 7. coder CLI (optional) =="
if command -v coder >/dev/null; then
  coder whoami 2>/dev/null | grep -q . && ok "coder CLI authenticated: $(coder whoami 2>/dev/null | tr -d '[]' | head -1)" \
    || warn "coder CLI present but not logged in (coder login)"
else
  warn "coder CLI not on this machine (only needed to start workspaces afterwards)"
fi

echo "== 8. flux objects that must survive the rename (sanity) =="
kubectl get clusterrepository nas >/dev/null 2>&1 \
  && ok "ClusterRepository nas exists (cluster-scoped; unaffected by the rename)" \
  || bad "ClusterRepository nas missing"
[ "$(kubectl get crd -o name 2>/dev/null | grep -c 'litellmmodels.litellm.home-operations.com')" -eq 1 ] \
  && ok "litellm CRDs present (they survive; the $NS_NEW charts re-install them)" \
  || warn "litellm CRDs not found by that name — check: kubectl get crd | grep litellm"

echo "== 9. flate validation of the rename (needs the branch checkout) =="
if [ -n "$REPO" ] && [ "$(git -C "$REPO" branch --show-current)" = "$BRANCH" ] && command -v flate >/dev/null; then
  if (cd "$REPO" && flate test all --path kubernetes/flux/cluster --allow-missing-kinds Secret --supply .github/flate-supply/secrets.yaml >/dev/null 2>&1); then
    ok "flate test all passed"
  else
    bad "flate test all failed (cd $REPO && flate test all --path kubernetes/flux/cluster --allow-missing-kinds Secret --supply .github/flate-supply/secrets.yaml)"
  fi
else
  warn "skipped (not on the branch checkout or flate missing)"
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "PREFLIGHT: $FAILURES failure(s) — do not open the window yet."
  exit 1
fi
echo "PREFLIGHT: all checks passed — the window can be opened (./02-window.sh)."
