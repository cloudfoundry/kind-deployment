#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/detect-runtime.sh"
source "$(dirname "$0")/tools.sh"

tools::install::helmfile

if [ "${IS_PODMAN}" = "true" ]; then
  export CILIUM_EXTRA_VALUES="${CILIUM_EXTRA_VALUES:-$(dirname "$0")/../assets/values/cilium-podman.yaml}"
fi

kind get kubeconfig --name cfk8s > temp/kubeconfig

source temp/secrets.sh

CILIUM_EXTRA_VALUES="${CILIUM_EXTRA_VALUES:-}" helmfile sync --kubeconfig temp/kubeconfig
