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
echo "Pai6 Full AutoDeploy Suite - Launcher (safe interactive)"
echo "This launcher runs the full automated deploy to Google Cloud Run (recommended)."
echo "It only prompts for essential values and logs actions to deploy.log."
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
chmod +x ./scripts/*.sh || true
./scripts/prep_environment.sh "$@"
./scripts/build_and_deploy.sh "$@"
./scripts/post_deploy_config.sh "$@"
echo "Launcher finished. Check logs/deploy.log for details."
