#!/usr/bin/env bash

set -e

. temp/secrets.sh
. scripts/tools.sh

tools::install::helmfile
tools::install::helm
tools::install::kind

kind get kubeconfig --name cfk8s > temp/kubeconfig
helmfile sync --kubeconfig temp/kubeconfig
