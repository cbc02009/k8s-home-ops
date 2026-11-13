#!/usr/bin/env bash
# ============================================================================
# 04-cleanup.sh — finish the rename: delete the old `ai` namespace and undo
# the temporary safety nets.
#
# ONLY run this after:
#   - 03-verify.sh came back all green, AND
#   - you have actually used the services in `llm` (logins still work, the
#     Coder workspace has your dotfiles/tools, litellm lanes answer).
#
# What it does (in order):
#   1. re-checks llm health (aborts if anything is wrong)
#   2. lists everything left in `ai` so you can review what gets destroyed
#   3. deletes the `ai` namespace  (its PVCs have reclaimPolicy Delete — the
#      underlying RBD/CephFS volumes are destroyed; the data was already
#      copied to `llm` by kopiur and/or PV rebind during the window)
#   4. reverts the PV reclaim policies to Delete (the pre-rename behaviour),
#      EXCEPT the Coder workspace-home PV, which is left on Retain on purpose:
#      that volume holds your dotfiles/toolchain and has no backup — keep it
#      restorable if a PVC is ever deleted by mistake.
#   5. prints the follow-up commits that should happen next.
# ============================================================================
set -uo pipefail

NS_OLD="ai"
NS_NEW="llm"
FAILURES=0
ok()   { printf '  OK   %s\n' "$*"; }
bad()  { printf '  FAIL %s\n' "$*"; FAILURES=$((FAILURES+1)); }

echo "== 1. pre-cleanup health of $NS_NEW =="
[ "$(kubectl get pvc -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="Bound"' | wc -l)" -eq 0 ] \
  && ok "all $NS_NEW PVCs Bound" || bad "some $NS_NEW PVCs not Bound"
[ -z "$(kubectl get helmrelease -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="True"')" ] \
  && ok "all $NS_NEW HelmReleases Ready" || bad "some $NS_NEW HelmReleases not Ready"
[ -z "$(kubectl get pods -n "$NS_NEW" --no-headers 2>/dev/null | awk '$4=="CrashLoopBackOff"||$4=="Error"')" ] \
  && ok "no pods in CrashLoopBackOff/Error in $NS_NEW" \
  || { bad "failing pods in $NS_NEW:"; kubectl get pods -n "$NS_NEW" | awk 'NR==1||$4=="CrashLoopBackOff"||$4=="Error"'; }
[ "$FAILURES" -eq 0 ] || { echo; echo "Abort: fix the failures above before deleting $NS_OLD."; exit 1; }

echo
echo "== 2. what is left in $NS_OLD (this all gets destroyed) =="
kubectl get all,pvc,restore,snapshotpolicy,snapshotschedule -n "$NS_OLD" 2>/dev/null | sed 's/^/    /' || true
echo
echo "    (PVCs here still hold the ORIGINAL data; the copied/rebound data in"
echo "     $NS_NEW has been verified in step 1. Deletion destroys the originals.)"
echo
printf 'Type the old namespace name to delete it: '
read -r ans
[ "$ans" = "$NS_OLD" ] || { echo "Aborted."; exit 0; }

echo
echo "== 3. deleting namespace $NS_OLD =="
kubectl delete ns "$NS_OLD" --timeout=600s 2>&1 || {
  echo "Deletion did not finish within 10 min. Check: kubectl get ns $NS_OLD"
  echo "If stuck on a finalizer: kubectl get ns $NS_OLD -o jsonpath='{.metadata.finalizers}'"
  exit 1
}
ok "namespace $NS_OLD deleted"

echo
echo "== 4. reverting PV safety nets =="
for pvc in llmkube-mayne-cache llmkube-model-cache paseo; do
  pv=$(kubectl get pvc -n "$NS_NEW" "$pvc" -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)
  if [ -n "$pv" ]; then
    kubectl patch pv "$pv" -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}' >/dev/null \
      && ok "$pv -> Delete" || bad "$pv patch failed"
  else
    warn "$pvc: no PV found"
  fi
done
coderpv=$(kubectl get pvc -n "$NS_NEW" -l com.coder.resource=true -o jsonpath='{.items[0].spec.volumeName}' 2>/dev/null || true)
if [ -n "$coderpv" ]; then
  warn "$coderpv (Coder workspace home) intentionally left on Retain — it has no backup; leave it, or change it yourself."
else
  warn "could not find the Coder workspace PVC in $NS_NEW (workspace not started yet?) — when it starts, its PV stays on Retain"
fi

echo
echo "== 5. follow-up commits (do these later, not now) =="
cat <<'EOF'
  a. Delete this directory (tools/rename-ai-to-llm/) in a small commit.
  b. opencode's `forceRename: opencode-svc` workaround is no longer needed
     (the opencode.ai collision only existed while the namespace was `ai`).
     Revert it in kubernetes/apps/llm/opencode/app/helmrelease.yaml and its
     HTTPRoute backendRef, together, in one commit.
  c. Optional, bigger: the Postgres cluster is still named `postgres-ai`
     (databases namespace). Renaming a CNPG cluster is a data operation —
     do it as its own planned event if at all.
EOF
