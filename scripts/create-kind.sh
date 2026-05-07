#!/usr/bin/env bash

set -e

# Auto-detect Docker or Podman
source "$(dirname "$0")/detect-runtime.sh"

configure_registry_mirror() {
  local cache_name=$1
  local remote_url=$2
  local registry_uri=$3

    # Configure registry mirrors for transparent caching
    echo "Configuring cache ${cache_name} on all nodes..."
    for node in $(kind get nodes --name cfk8s); do
        # Create containerd registry config directories
        ${CONTAINER_RUNTIME} exec "$node" mkdir -p /etc/containerd/certs.d/${registry_uri}

        # Configure registry to use cache as mirror (expand variables!)
        cat <<EOF | ${CONTAINER_RUNTIME} exec -i "$node" sh -c "cat > /etc/containerd/certs.d/${registry_uri}/hosts.toml"
server = "${remote_url}"

[host."http://${cache_name}:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF
    done
}

evaluate_progress_option() {
    # Podman compose does not support --progress
    if [ "${IS_PODMAN}" = "true" ]; then
      echo ""
    else
      echo "--progress plain"
    fi
}

setup_registry_caches() {
    echo "Starting registry pull-through caches with ${COMPOSE_CMD}..."
    ${COMPOSE_CMD} -p cache -f "${script_full_path}/docker-compose-registries.yaml" $(evaluate_progress_option) up -d

    configure_registry_mirror "docker-io" "https://registry-1.docker.io" "docker.io"
    configure_registry_mirror "ghcr-io" "https://ghcr.io" "ghcr.io"
    configure_registry_mirror "quay-io" "https://quay.io" "quay.io"
}

setup_nfs() {
    echo "Starting NFS server with ${COMPOSE_CMD}..."
    ${COMPOSE_CMD} -p nfs -f "${script_full_path}/docker-compose-nfs.yaml" $(evaluate_progress_option) up -d
}

script_full_path=$(dirname "$0")

# When running under Podman, ensure the Podman VM is ready (NFS modules, inotify, …)
if [ "${IS_PODMAN}" = "true" ]; then
  echo "Podman detected – ensuring Podman VM is configured..."
  "${script_full_path}/setup-podman-vm.sh"
fi

if kind get clusters | grep -q "cfk8s"; then
  echo "Kind cluster 'cfk8s' already exists."
  exit 0
fi

kind create cluster --name "cfk8s" --config="$script_full_path/../kind.yaml"

echo "Applying taints to workload nodes..."
kubectl taint nodes -l cloudfoundry.org/cell=true cloudfoundry.org/cell=true:NoSchedule --overwrite || true

if [ "${DISABLE_CACHE}" != "true" ]; then
  echo "Setting up registry caches..."

  setup_registry_caches
fi


if [ "${INSTALL_OPTIONAL_COMPONENTS:-true}" = "true" ]; then
  echo "Setting up NFS server..."

  setup_nfs
fi

