#!/usr/bin/env bash

set -euo pipefail

configure_registry_mirror() {
  local cache_name=$1
  local remote_url=$2
  local registry_uri=$3

    # Configure registry mirrors for transparent caching
    echo "Configuring cache ${cache_name} on all nodes..."
    for node in $(kind get nodes --name cfk8s); do
        # Create containerd registry config directories
        docker exec "$node" mkdir -p /etc/containerd/certs.d/"${registry_uri}"

        # Configure registry to use cache as mirror (expand variables!)
        cat <<EOF | docker exec -i "$node" sh -c "cat > /etc/containerd/certs.d/\"${registry_uri}\"/hosts.toml"
server = "${remote_url}"

[host."http://${cache_name}:5000"]
  capabilities = ["pull", "resolve"]
  skip_verify = true
EOF
    done
}

setup_registry_caches() {
    echo "Starting registry pull-through caches with docker-compose..."
    docker compose -p cache -f "${script_full_path}/docker-compose.yaml" --progress plain up -d

    configure_registry_mirror "docker-io" "https://registry-1.docker.io" "docker.io"
    configure_registry_mirror "ghcr-io" "https://ghcr.io" "ghcr.io"
    configure_registry_mirror "quay-io" "https://quay.io" "quay.io"
}

script_full_path=$(dirname "$0")

if kind get clusters | grep -q "cfk8s"; then
  echo "Kind cluster 'cfk8s' already exists."
  exit 0
fi

kind create cluster --name "cfk8s" --config="$script_full_path/../kind.yaml"

if [ "${DISABLE_CACHE:-}" != "true" ]; then
  echo "Setting up registry caches..."

  setup_registry_caches
fi

helm upgrade --install --repo https://helm.cilium.io/ cilium cilium --version "1.18.4" --namespace kube-system --wait --values "$script_full_path/../assets/values/cilium.yaml"

echo "Waiting for nodes to become ready after CNI installation..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo "Applying taints to workload nodes..."
kubectl taint nodes -l cloudfoundry.org/cell=true cloudfoundry.org/cell=true:NoSchedule --overwrite || true

kubectl cluster-info

corefile=$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | sed '/kubernetes/i \
    rewrite name regex (.*)\\.127-0-0-1\\.nip\\.io istio-gateway-istio.default.svc.cluster.local answer auto\
')
kubectl -n kube-system patch configmap coredns --type=json \
  -p="$(jq -n --arg cf "$corefile" '[{"op":"replace","path":"/data/Corefile","value":$cf}]')"

kubectl -n kube-system rollout restart deployment/coredns

