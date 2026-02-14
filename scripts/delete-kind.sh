#!/usr/bin/env bash

set -euo pipefail

script_full_path=$(dirname "$0")

kind delete cluster --name cfk8s

# Remove registry cache containers using docker-compose
echo "Deleting registry cache containers..."
docker compose -p cache -f "${script_full_path}/docker-compose.yaml" --progress plain down
