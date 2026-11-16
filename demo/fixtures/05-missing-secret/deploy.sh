#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DEPLOY_TOKEN:-}" ]; then
  echo "ERROR: 401 Unauthorized — DEPLOY_TOKEN is not set" >&2
  exit 1
fi

echo "deployed with token ending in ...${DEPLOY_TOKEN: -4}"
