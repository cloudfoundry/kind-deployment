#!/usr/bin/env bash

CATS_PATH="${CATS_PATH:-../cf-acceptance-tests}"
CATS_TEMPLATE="${CATS_TEMPLATE:-.github/cats-config.tpl}"
CATS_CONFIG="${CATS_CONFIG:-.github/cats-config.json}"

[ ! -d "${CATS_PATH}" ] && echo "Error: CATS_PATH '${CATS_PATH}' does not exist, ensure it points to a local clone of cf-acceptance-tests." && exit 1
[ ! -f "${CATS_TEMPLATE}" ] && echo "Error: CATS_TEMPLATE '${CATS_TEMPLATE}' does not exist, ensure it points to a valid template file." && exit 1

source temp/secrets.sh
python3 -c 'import os,sys;[sys.stdout.write(os.path.expandvars(l)) for l in sys.stdin]' < ${CATS_TEMPLATE} > ${CATS_CONFIG}
echo "CATS configuration rendered to ${CATS_CONFIG}."

if [ -n "${RENDER_ONLY}" ]; then
  exit 0
fi

CONFIG=$(realpath ${CATS_CONFIG}) ${CATS_PATH}/bin/test --timeout=180m --procs=4 --flake-attempts=1
