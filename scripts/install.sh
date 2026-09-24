#!/usr/bin/env bash

set -e

. temp/secrets.sh
. scripts/tools.sh

tools::install::helmfile
tools::install::helm
tools::install::kind

if [[ "${LOCAL_DEPLOYMENT}" == "true" ]]; then
  kind get kubeconfig --name cfk8s > temp/kubeconfig
  helmfile sync --kubeconfig temp/kubeconfig
else
  helmfile sync --state-values-file assets/values/gardener.yaml
fi
