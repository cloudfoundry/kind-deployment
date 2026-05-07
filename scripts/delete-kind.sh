#!/usr/bin/env bash

set -e

script_full_path=$(dirname "$0")

kind delete cluster --name cfk8s

# Detect container runtime behind docker (Docker vs Podman)
if echo $(docker version) | grep -qi 'Podman'; then
  container_runtime_spects=""
else
  container_runtime_spects="--progress plain"
fi

# Remove registry cache containers using docker-compose
echo "Deleting registry cache containers..."
docker compose -p cache -f "${script_full_path}/docker-compose-registries.yaml" $container_runtime_spects down
docker compose -p nfs -f "${script_full_path}/docker-compose-nfs.yaml" $container_runtime_spects down
