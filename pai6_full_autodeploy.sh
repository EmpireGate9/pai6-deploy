#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export LOG="logs/deploy.log"
mkdir -p "$(dirname "$LOG")"
export DRY_RUN="${DRY_RUN:-0}"
export CONFIRM="${CONFIRM:-1}"
echo "[pai6] starting autodeploy suite... DRY_RUN=$DRY_RUN"
bash infra/autodeploy/pai6_full_autodeploy.sh
echo "[pai6] autodeploy finished."
