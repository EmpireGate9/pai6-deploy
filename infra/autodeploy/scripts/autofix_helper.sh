#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DRY_RUN="${DRY_RUN:-0}"
CONFIRM="${CONFIRM:-0}"
LOCKFILE="${LOCKFILE:-/tmp/pai6_autodeploy.lock}"
LOG="${LOG:-logs/deploy.log}"
TS(){ date +"%Y-%m-%d %H:%M:%S"; }
log(){ echo "[$(TS)] $*" | tee -a "$LOG"; }
run(){ if [[ "$DRY_RUN" == "1" ]]; then log "[dry-run] $*"; else eval "$@" ; fi }
acquire_lock(){
  if [[ -e "$LOCKFILE" ]]; then
    log "Lock exists at $LOCKFILE. Another deploy running?"; exit 1
  fi
  echo $$ > "$LOCKFILE"
}
release_lock(){ rm -f "$LOCKFILE"; }
confirm(){
  if [[ "$CONFIRM" == "1" ]]; then return 0; fi
  read -p "Confirm proceed? [y/N]: " ans; [[ "$ans" == "y" || "$ans" == "Y" ]]
}
trap 'release_lock' EXIT
mkdir -p "$(dirname "$LOG")"
# simple autofix helper (best-effort)
set -euo pipefail
PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}
REGION=${REGION:-me-central1}
ARTIFACT_REPO=${ARTIFACT_REPO:-pai6-artifacts}
echo "[autofix] ensure apis..."
gcloud services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com monitoring.googleapis.com --project="$PROJECT_ID" || true
echo "[autofix] ensure artifact repo..."
if ! gcloud artifacts repositories describe "$ARTIFACT_REPO" --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$ARTIFACT_REPO" --repository-format=docker --location="$REGION" --project="$PROJECT_ID" || true
fi
echo "[autofix] done"
