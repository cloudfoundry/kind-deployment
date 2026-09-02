#!/usr/bin/env bash

set -e

. scripts/tools.sh

configure_registry_mirror() {
  local cache_name=$1
  local remote_url=$2
  local registry_uri=$3

    # Configure registry mirrors for transparent caching
    echo "Configuring cache ${cache_name} on all nodes..."
    for node in $(kind get nodes --name cfk8s); do
        # Create containerd registry config directories
        docker exec "$node" mkdir -p /etc/containerd/certs.d/${registry_uri}

        # Configure registry to use cache as mirror (expand variables!)
        cat <<EOF | docker exec -i "$node" sh -c "cat > /etc/containerd/certs.d/${registry_uri}/hosts.toml"
server = "${remote_url}"

[host."http://${cache_name}:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF
    done
}

setup_registry_caches() {
    echo "Starting registry pull-through caches with docker-compose..."
    docker compose -p cache -f "${script_full_path}/docker-compose-registries.yaml" --progress plain up -d

    configure_registry_mirror "docker-io" "https://registry-1.docker.io" "docker.io"
    configure_registry_mirror "ghcr-io" "https://ghcr.io" "ghcr.io"
    configure_registry_mirror "quay-io" "https://quay.io" "quay.io"
}

setup_nfs() {
    echo "Starting NFS server with docker-compose..."
    docker compose -p nfs -f "${script_full_path}/docker-compose-nfs.yaml" --progress plain up -d
}

script_full_path=$(dirname "$0")

tools::install::kind
tools::install::kubectl
tools::install::yq

if kind get clusters | grep -q "cfk8s"; then
  echo "Kind cluster 'cfk8s' already exists."
  exit 0
fi

kind_config="$script_full_path/../kind.yaml"
if [ "${CNI}" = "calico" ]; then
  echo "Removing networking.kubeProxyMode from kind config for Calico CNI..."
  yq eval 'del(.networking.kubeProxyMode)' "$kind_config" > "$kind_config.tmp"
  kind_config="$kind_config.tmp"
fi

kind create cluster --name "cfk8s" --config=$kind_config

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

