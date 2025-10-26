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
# prep_environment.sh - prepares environment, prompts an initial few values, safe-mode
set -euo pipefail
LOG=../logs/deploy.log
mkdir -p ../logs
echo "[prep] $(date -u) - starting" | tee -a $LOG
read -rp "Project ID [${PROJECT_ID:-overseas-superior}]: " PROJECT_ID; PROJECT_ID=${PROJECT_ID:-overseas-superior}
read -rp "Region [${REGION:-me-central1}]: " REGION; REGION=${REGION:-me-central1}
read -rp "Admin email [${ADMIN_EMAIL:-nasserjawabreh9@gmail.com}]: " ADMIN_EMAIL; ADMIN_EMAIL=${ADMIN_EMAIL:-nasserjawabreh9@gmail.com}
export PROJECT_ID REGION ADMIN_EMAIL
gcloud config set project "$PROJECT_ID" | tee -a $LOG || true
gcloud services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com monitoring.googleapis.com logging.googleapis.com iam.googleapis.com --project="$PROJECT_ID" | tee -a $LOG || true
echo "[prep] done" | tee -a $LOG
