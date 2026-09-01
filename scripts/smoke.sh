#!/usr/bin/env bash

set -euo pipefail

# Extra args are forwarded to bin/test, e.g. `bash scripts/smoke.sh --focus="…"`.

SMOKE_PATH="${SMOKE_PATH:-../cf-smoke-tests}"
SMOKE_TEMPLATE="${SMOKE_TEMPLATE:-.github/smoke-config.tpl}"
SMOKE_CONFIG="${SMOKE_CONFIG:-.github/smoke-config.json}"

if [ ! -d "${SMOKE_PATH}" ]; then
  echo "Error: SMOKE_PATH '${SMOKE_PATH}' does not exist, ensure it points to a local clone of cf-smoke-tests."
  exit 1
fi
if [ ! -f "${SMOKE_TEMPLATE}" ]; then
  echo "Error: SMOKE_TEMPLATE '${SMOKE_TEMPLATE}' does not exist, ensure it points to a valid template file."
  exit 1
fi

source temp/secrets.sh
python3 -c 'import os,sys;[sys.stdout.write(os.path.expandvars(l)) for l in sys.stdin]' < "${SMOKE_TEMPLATE}" > "${SMOKE_CONFIG}"
echo "SMOKE configuration rendered to ${SMOKE_CONFIG}."

if [ -n "${RENDER_ONLY:-}" ]; then
  exit 0
fi

CONFIG=$(realpath "${SMOKE_CONFIG}") "${SMOKE_PATH}/bin/test" --timeout=30m --procs=2 "$@"
