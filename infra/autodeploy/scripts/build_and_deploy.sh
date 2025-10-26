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
# build_and_deploy.sh - builds images via Cloud Build and deploys to Cloud Run
set -euo pipefail
LOG=../logs/deploy.log
echo "[build] $(date -u) - starting" | tee -a $LOG
PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project 2>/dev/null)}
REGION=${REGION:-me-central1}
ARTIFACT_REPO=${ARTIFACT_REPO:-pai6-artifacts}
mkdir -p ../logs
# create artifact repo if missing (best-effort)
if ! gcloud artifacts repositories describe "$ARTIFACT_REPO" --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
  gcloud artifacts repositories create "$ARTIFACT_REPO" --repository-format=docker --location="$REGION" --project="$PROJECT_ID" || true
fi
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet || true
# build core
if [ -d ../engine/core ]; then
  gcloud builds submit ../engine/core --tag "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/pai6-core:v1" --project="$PROJECT_ID" || echo "[build] core build failed" | tee -a $LOG
fi
# build frontend as nginx container
if [ -d ../dashboard ]; then
  TMPDIR=$(mktemp -d)
  cp -r ../dashboard/* "$TMPDIR/"
  cat > "$TMPDIR/Dockerfile" <<'DOCK'
FROM nginx:stable-alpine
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
DOCK
  gcloud builds submit "$TMPDIR" --tag "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/pai6-frontend:v1" --project="$PROJECT_ID" || echo "[build] frontend build failed" | tee -a $LOG
  rm -rf "$TMPDIR"
fi
# deploy to Cloud Run
if gcloud container images list --repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}" --project="$PROJECT_ID" | grep -q pai6-core; then
  gcloud run deploy pai6-core --image "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/pai6-core:v1" --region="$REGION" --platform=managed --allow-unauthenticated --project="$PROJECT_ID" || echo "[deploy] core deploy failed" | tee -a $LOG
fi
if gcloud container images list --repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}" --project="$PROJECT_ID" | grep -q pai6-frontend; then
  gcloud run deploy pai6-frontend --image "${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/pai6-frontend:v1" --region="$REGION" --platform=managed --allow-unauthenticated --project="$PROJECT_ID" || echo "[deploy] frontend deploy failed" | tee -a $LOG
fi
echo "[build] finished" | tee -a $LOG
