#!/usr/bin/env bash

set -e

# Auto-detect Docker or Podman
source "$(dirname "$0")/detect-runtime.sh"
source "$(dirname "$0")/tools.sh"

script_full_path=$(dirname "$0")

tools::install::kind

kind delete cluster --name cfk8s

# Remove registry cache containers
echo "Deleting registry cache containers..."
${COMPOSE_CMD} -p cache -f "${script_full_path}/docker-compose-registries.yaml" down

if [ "${INSTALL_OPTIONAL_COMPONENTS:-true}" = "true" ]; then
  echo "Stopping NFS server..."
  ${COMPOSE_CMD} -p nfs -f "${script_full_path}/docker-compose-nfs.yaml" down
fi
