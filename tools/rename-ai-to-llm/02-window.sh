#!/usr/bin/env bash
# ============================================================================
# 02-window.sh — the ai -> llm namespace rename cutover.
#
# RUN THIS FROM A MACHINE THAT SURVIVES THE WINDOW: your laptop, or the
#   `dev` LXC on the NAS (where the opencode agent lives and can drive the
#   run itself). kubectl, git (authenticated to GitHub), jq and the `flux`
#   CLI must be available. Do NOT run it from a pod inside the `ai`
#   namespace — those die during the cutover.
#
# If the agent runs it: use --yes (the interactive pause has no TTY to read
# from in the background) and start it in the background. The agent's LLM is
# routed through litellm.ctec.run -> the `ai` namespace, so the agent is
# deaf for the length of the Phase B downtime and wakes up again when `llm`
# converges; the script is fully self-driving and idempotent, and writes
# window-*.log next to itself for post-hoc inspection.
#
# Prerequisite: you are in a clone of k8s-home-ops checked out on branch
#   `rename-ai-to-llm`   (git fetch origin && git checkout rename-ai-to-llm)
#
# Usage:
#   ./tools/rename-ai-to-llm/02-window.sh            # asks before Phase B
#   ./tools/rename-ai-to-llm/02-window.sh --yes      # fully hands-off
#
# The script is IDEMPOTENT: every step checks whether it already happened
# (e.g. a PVC is already Bound, a PV is already Retain) and skips ahead, so
# you can re-run it any number of times if it is interrupted.
# ============================================================================
set -euo pipefail

# --- configuration ----------------------------------------------------------
NS_OLD="ai"
NS_NEW="llm"
BRANCH="rename-ai-to-llm"
REPO="$(git rev-parse --show-toplevel)"
RESTORES_DIR="$REPO/tools/rename-ai-to-llm/restores"
# The five PVCs moved by kopiur restore (target.pvc; one file each in restores/)
KOPAN_APPS=(hermes litellm memini opencode open-webui)
# The four PVs moved by rebind (name | accessModes | size | storageClass | mode)
#   bind      = new PVC is pre-created in llm with spec.volumeName (Bound)
#   available = PV is left Available; the Coder terraform PVC binds it on
#               workspace start (static binding: same class/modes/size)
REBINDS=(
  "llmkube-mayne-cache|ReadWriteOnce|200Gi|openebs-hostpath|bind"
  "llmkube-model-cache|ReadWriteMany|200Gi|ceph-filesystem|bind"
  "paseo|ReadWriteOnce|20Gi|ceph-block|bind"
  "coder-527a7bfc-cf01-40ed-a204-254d0c73fc7d-home|ReadWriteOnce|10Gi|ceph-filesystem|available"
)

LOGFILE="$REPO/tools/rename-ai-to-llm/window-$(date +%Y%m%d-%H%M%S).log"
log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOGFILE"; }
die() { log "FATAL: $*"; exit 1; }
step() { log ""; log "=== $* ==="; }

[ "$(git -C "$REPO" branch --show-current)" = "$BRANCH" ] || die "run from a checkout of branch $BRANCH (currently: $(git -C "$REPO" branch --show-current) in $REPO)"
command -v kubectl >/dev/null || die "kubectl not found"
command -v jq >/dev/null || die "jq not found (used to copy the kopiur secret and find PVC consumers)"
kubectl get ns >/dev/null 2>&1 || die "cluster not reachable"
log "repo: $REPO"
log "log:  $LOGFILE"

# --- Phase A: pre-seed the new namespace (NO DOWNTIME) ----------------------
phaseA() {
  step "A1: ensure namespace $NS_NEW exists (matches the git-rendered object)"
  if ! kubectl get ns "$NS_NEW" >/dev/null 2>&1; then
    kubectl apply -f - <<EOF | tee -a "$LOGFILE"
apiVersion: v1
kind: Namespace
metadata:
  name: $NS_NEW
  annotations:
    kustomize.toolkit.fluxcd.io/prune: disabled
  labels:
    resource.kubernetes.io/admin-access: "true"
EOF
  else
    log "namespace $NS_NEW already exists"
  fi

  step "A2: give the kopiur mover its repository credentials in $NS_NEW"
  if kubectl get secret kopiur-nas-secret -n "$NS_NEW" >/dev/null 2>&1; then
    log "kopiur-nas-secret already present in $NS_NEW"
  else
    kubectl get secret kopiur-nas-secret -n "$NS_OLD" -o json \
      | jq '.metadata = {"name":"kopiur-nas-secret","namespace":"'$NS_NEW'"}' \
      | kubectl apply -n "$NS_NEW" -f - | tee -a "$LOGFILE"
  fi

  step "A3: apply the five one-shot cross-ns Restores (kopiur -> $NS_NEW)"
  kubectl apply -f "$RESTORES_DIR" | tee -a "$LOGFILE"

  step "A4: wait for all five PVCs in $NS_NEW to be populated from real snapshots (up to 90 min)"
  local end=$(( $(date +%s) + 5400 ))
  while :; do
    local pending=0
    for app in "${KOPAN_APPS[@]}"; do
      local st phase reason resolution snap
      # target.pvc Restores report at the top level: .status.phase, the
      # Ready condition's reason, and .status.resolved (not a claims map).
      st=$(kubectl get restore -n "$NS_NEW" "$app" -o jsonpath='{.status.phase} {.status.conditions[?(@.type=="Ready")].reason} {.status.resolved.resolution} {.status.resolved.kopiaSnapshotID}' 2>/dev/null || true)
      read -r phase reason resolution snap <<<"$st"
      case "$phase" in
        Completed|Populated)
          if [ "$resolution" = "Snapshot" ] && [ "$reason" = "RestoreSucceeded" ]; then
            log "  $app: $phase from real snapshot ${snap:-?} — OK"
          else
            log "  $app: $phase but NO SNAPSHOT WAS FOUND (reason=$reason resolution=$resolution) — the source data was NOT copied. Do NOT proceed with Phase B for this app."
            pending=2
          fi
          ;;
        "")
          log "  $app: restore has no status yet (controller may still be resolving the source)"
          pending=1
          ;;
        *)
          log "  $app: $phase (reason=${reason:-?})"
          pending=1
          ;;
      esac
    done
    [ "$pending" = 2 ] && die "at least one app has no source snapshot; check: kubectl get snapshotpolicy -n $NS_OLD; kubectl describe restore -n $NS_NEW <app> (and .status.logTail). Wait for a fresh snapshot and re-run."
    [ "$pending" = 0 ] && break
    [ "$(date +%s)" -gt "$end" ] && die "timed out waiting for restores; current state: kubectl get restore -n $NS_NEW"
    sleep 30
  done
  log "Phase A complete: all five kopiur volumes are populated in $NS_NEW."
}

# --- Phase B: the cutover (DOWNTIME for the ai namespace) --------------------
phaseB() {
  step "B1: suspend every Kustomization in $NS_OLD (no more re-apply/prune races)"
  kubectl get kustomization -n "$NS_OLD" --no-headers 2>/dev/null | awk '{print "  suspending " $1}'
  kubectl patch kustomization -n "$NS_OLD" --all -p '{"spec":{"suspend":true}}' --type=merge >/dev/null

  step "B2: rebind the four PVs out of $NS_OLD"
  local row name modes size sc mode pv
  for row in "${REBINDS[@]}"; do
    IFS='|' read -r name modes size sc mode <<<"$row"
    pv=$(kubectl get pvc -n "$NS_OLD" "$name" -o jsonpath='{.spec.volumeName}' 2>/dev/null || true)
    [ -n "${pv:-}" ] || { log "  $name: PV no longer referenced by a $NS_OLD PVC (already rebound?) — skipping"; continue; }

    # 0) stop the pods mounting this PVC first: the kubernetes.io/pvc-protection
    #    finalizer keeps an in-use PVC from actually deleting, which would hang
    #    the --timeout below. (These pods are being replaced in $NS_NEW anyway.)
    local consumers t
    consumers=$(kubectl get pods -n "$NS_OLD" -o json 2>/dev/null \
      | jq -r --arg pvc "$name" '.items[] | select([.spec.volumes[]? | .persistentVolumeClaim.claimName] | index($pvc)) | .metadata.name' 2>/dev/null || true)
    if [ -n "$consumers" ]; then
      log "  $name: stopping consumer pods: $(echo $consumers | tr '\n' ' ')"
      # shellcheck disable=SC2086
      kubectl delete pod -n "$NS_OLD" $consumers --ignore-not-found --timeout=60s >/dev/null 2>&1 || true
      for c in $consumers; do
        t=0
        while kubectl get pod -n "$NS_OLD" "$c" >/dev/null 2>&1; do
          t=$((t+2)); [ $t -gt 90 ] && break
          sleep 2
        done
      done
    fi

    # 1) protect the data
    [ "$(kubectl get pv "$pv" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')" = "Retain" ] \
      || kubectl patch pv "$pv" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' >/dev/null

    # 2) release it from the old namespace
    if kubectl get pvc -n "$NS_OLD" "$name" >/dev/null 2>&1; then
      log "  $name ($pv): deleting $NS_OLD PVC (pods mounting it will die now)"
      kubectl delete pvc -n "$NS_OLD" "$name" --timeout=120s >/dev/null
    fi
    # wait until the PV is released
    local t=0
    while :; do
      local ph; ph=$(kubectl get pv "$pv" -o jsonpath='{.status.phase}')
      [ "$ph" != "Bound" ] && break
      t=$((t+5)); [ $t -gt 240 ] && die "$pv stuck in Bound; kubectl describe pv $pv"
      sleep 5
    done

    if [ "$mode" = "bind" ]; then
      # 3) point the PV at the new namespaced claim and let the controller bind it
      kubectl patch pv "$pv" --type=merge -p '{"spec":{"claimRef":{"namespace":"'$NS_NEW'","name":"'$name'"}},"metadata":{"annotations":{"pv.kubernetes.io/bound-by-controller":""}}}' >/dev/null
      if ! kubectl get pvc -n "$NS_NEW" "$name" >/dev/null 2>&1; then
        kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $name
  namespace: $NS_NEW
spec:
  accessModes:
    - $modes
  storageClassName: $sc
  resources:
    requests:
      storage: $size
  volumeName: $pv
EOF
      fi
      t=0
      while [ "$(kubectl get pvc -n "$NS_NEW" "$name" -o jsonpath='{.status.phase}')" != "Bound" ]; do
        t=$((t+5)); [ $t -gt 120 ] && die "$NS_NEW/$name did not bind to $pv"
        sleep 5
      done
      log "  $name: $pv rebound to $NS_NEW/$name (Bound, zero-copy)"
    else
      # leave it Available; the Coder terraform PVC (same class/modes/size)
      # static-binds it the next time the workspace starts.
      kubectl patch pv "$pv" --type=merge -p '{"spec":{"claimRef":null}}' >/dev/null
      t=0
      while [ "$(kubectl get pv "$pv" -o jsonpath='{.status.phase}')" != "Available" ]; do
        t=$((t+5)); [ $t -gt 120 ] && die "$pv did not return to Available"
        sleep 5
      done
      log "  $name: $pv left Available (Coder workspace home; binds when the workspace starts)"
    fi
  done

  step "B3: publish the rename (this is the point of no easy return)"
  git -C "$REPO" push origin "$BRANCH:main" 2>&1 | tee -a "$LOGFILE"

  step "B4: make cluster-apps pick it up immediately"
  flux reconcile kustomization -n flux-system cluster-apps 2>&1 | tee -a "$LOGFILE" || log "  (flux CLI reconcile failed; it will pick the revision up on its 30m interval — continuing to watch)"

  step "B5: wait for $NS_NEW to converge (up to 30 min): all KSs and HelmReleases Ready"
  local end=$(( $(date +%s) + 1800 ))
  while :; do
    local bad_ks bad_hr
    bad_ks=$(kubectl get kustomization -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="True"' || true)
    bad_hr=$(kubectl get helmrelease -n "$NS_NEW" --no-headers 2>/dev/null | awk '$3!="True"' || true)
    if [ -z "$bad_ks" ] && [ -z "$bad_hr" ] && kubectl get kustomization -n "$NS_NEW" --no-headers 2>/dev/null | grep -q .; then
      log "all $NS_NEW Kustomizations and HelmReleases are Ready"
      break
    fi
    log "  not ready yet: KS:$(echo "$bad_ks" | wc -l) HR:$(echo "$bad_hr" | wc -l)"
    [ "$(date +%s)" -gt "$end" ] && { log "TIMEOUT — current state:"; kubectl get kustomization,helmrelease -n "$NS_NEW"; die "see the lines above for what is not ready"; }
    sleep 20
  done
  kubectl get kustomization -n "$NS_NEW" | tee -a "$LOGFILE"
  kubectl get helmrelease -n "$NS_NEW" | tee -a "$LOGFILE"

  step "B6: apply the Talos control-plane patch (talos API access: $NS_OLD -> $NS_NEW)"
  if command -v just >/dev/null; then
    (cd "$REPO" && just talos apply-node) 2>&1 | tee -a "$LOGFILE" || log "  WARN: 'just talos apply-node' failed — run it manually (non-fatal)"
  else
    log "  SKIP: just CLI not found — run: just talos apply-node"
  fi

  step "Cutover complete."
  cat <<EOF | tee -a "$LOGFILE"

Next steps (do these, in order):
  1. ./tools/rename-ai-to-llm/03-verify.sh     # proves the data and services landed
  2. Only if you are continuing with Coder:
         coder update <name>
     (moves the workspace to the new template version, namespace $NS_NEW;
      its home PVC static-binds the retained PV. NOT plain `coder start` —
      that would run the OLD template version, which still points at the
      deleted $NS_OLD namespace. If you are dropping the Coder path, skip
      this — the PV stays on Retain until you delete it.)
  3. When everything checks out (and you have had a chance to use it):
     ./tools/rename-ai-to-llm/04-cleanup.sh    # deletes the old $NS_OLD namespace
EOF
}

# --- driver -----------------------------------------------------------------
if [[ "${1:-}" = "--yes" ]]; then
  phaseA
  phaseB
else
  phaseA
  step "PAUSE before the destructive cutover (Phase B)."
  cat <<EOF
Phase A is done: the five kopiur volumes are populated in $NS_NEW.
Nothing in $NS_OLD has been touched yet — the cluster is still fully up.

Phase B will, in order:
  - suspend all $NS_OLD Kustomizations
  - REBIND 4 PVs (llmkube-mayne-cache, llmkube-model-cache, paseo, the Coder
    workspace home) — pods in $NS_OLD that mount them will die
  - push branch $BRANCH to main  (Flux then prunes the $NS_OLD Kustomizations
    and their Helm releases, and applies the $NS_NEW tree)
  - wait for convergence, apply the Talos patch

There is no automatic rollback after the push (see README.md "Rollback").
EOF
  printf 'Type the new namespace name to continue: '
  read -r ans
  [ "$ans" = "$NS_NEW" ] || die "aborted (did not type $NS_NEW)"
  phaseB
fi
