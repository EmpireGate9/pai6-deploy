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
# post_deploy_config.sh - post-deploy tasks: domain mapping instructions, config manager stub, enable monitoring
set -euo pipefail
LOG=../logs/deploy.log
PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}
REGION=${REGION:-me-central1}
DOMAIN=${DOMAIN:-pai-6.overseas-superior.com}
echo "[post] $(date -u) - starting" | tee -a $LOG
# try to create domain mapping (will fail if domain not verified)
if gcloud run services list --region="$REGION" --project="$PROJECT_ID" | grep -q pai6-frontend; then
  FRONTEND_URL=$(gcloud run services describe pai6-frontend --region="$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null || true)
  echo "Frontend URL: ${FRONTEND_URL:-N/A}" | tee -a $LOG
  read -rp "Attempt to create domain-mapping for ${DOMAIN}? (y/N): " domans
  if [[ "${domans}" =~ ^[Yy] ]]; then
    gcloud run domain-mappings create --service=pai6-frontend --domain="$DOMAIN" --region="$REGION" --project="$PROJECT_ID" || echo "[post] domain mapping failed" | tee -a $LOG
    echo "If domain mapping failed, verify domain ownership in Search Console and add DNS records as instructed." | tee -a $LOG
  fi
fi
# create a minimal 'Dynamic Config Manager' stub file
mkdir -p ../engine/config
cat > ../engine/config/dynamic_config.json <<'JSON'
{"last_updated":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","notes":"Use /admin/config in dashboard to edit settings."}
JSON
echo "[post] finished" | tee -a $LOG
