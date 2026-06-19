#!/usr/bin/env bash

set -e
set -o pipefail

# renovate: dataSource=github-releases depName=helmfile/helmfile
export HELMFILE_VERSION="1.5.5"
# renovate: dataSource=github-releases depName=helm/helm
export HELM_VERSION="4.2.2"
# renovate: dataSource=github-releases depName=kubernetes-sigs/kind
export KIND_VERSION="0.32.0"
# renovate: dataSource=github-releases depName=kubernetes/kubectl
export KUBECTL_VERSION="1.36.2"
export TOOLS_BIN_DIR="$(realpath $(dirname "${BASH_SOURCE[0]}"))/../bin"

function tools::export_path() {
    # if path is already in PATH, do not add it again
    if [[ ":$PATH:" != *":$TOOLS_BIN_DIR:"* ]]; then
        export PATH="${TOOLS_BIN_DIR}:${PATH}"
    fi
}

function util::tools::os() {
  case "$(uname)" in
    "Darwin")
      echo "darwin"
      ;;

    "Linux")
      echo "linux"
      ;;

    *)
      util::print::error "Unknown OS \"$(uname)\""
      exit 1
  esac
}

function util::tools::arch() {
  case "$(uname -m)" in
    arm64|aarch64)
      echo "arm64"
      ;;

    amd64|x86_64)
        echo "amd64"
      ;;

    *)
      util::print::error "Unknown Architecture \"$(uname -m)\""
      exit 1
  esac
}

function tools::install::helmfile() {
    tools::export_path

    local bin="${TOOLS_BIN_DIR}/helmfile"
    if [[ -x "${bin}" ]] && "${bin}" version --output short 2>/dev/null | grep -q "^v\{0,1\}${HELMFILE_VERSION}\b"; then
        return 0
    fi

    local os=$(util::tools::os)
    local arch=$(util::tools::arch)
    local url="https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_${os}_${arch}.tar.gz"
    mkdir -p "${TOOLS_BIN_DIR}"

    echo "Installing helmfile from ${url}..."
    curl -sSL -o - "${url}" | tar -xz -C "${TOOLS_BIN_DIR}" helmfile
}

function tools::install::helm() {
    tools::export_path

    local bin="${TOOLS_BIN_DIR}/helm"
    if [[ -x "${bin}" ]] && "${bin}" version --short 2>/dev/null | grep -q "^v${HELM_VERSION}\b"; then
        return 0
    fi

    local os=$(util::tools::os)
    local arch=$(util::tools::arch)
    local url="https://get.helm.sh/helm-v${HELM_VERSION}-${os}-${arch}.tar.gz"
    mkdir -p "${TOOLS_BIN_DIR}"

    echo "Installing helm from ${url}..."
    # The tarball structure is darwin-amd64/helm
    curl -sSL -o - "${url}" | tar -xz -C "${TOOLS_BIN_DIR}" --strip-components=1 "${os}-${arch}/helm"
}

function tools::install::kubectl() {
    tools::export_path

    local bin="${TOOLS_BIN_DIR}/kubectl"
    if [[ -x "${bin}" ]] && "${bin}" version --client 2>/dev/null | grep -q "v${KUBECTL_VERSION}\b"; then
        return 0
    fi

    local os=$(util::tools::os)
    local arch=$(util::tools::arch)
    local url="https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${os}/${arch}/kubectl"
    mkdir -p "${TOOLS_BIN_DIR}"

    echo "Installing kubectl from ${url}..."
    curl -sSL -o "${TOOLS_BIN_DIR}/kubectl" "${url}"
    chmod +x "${TOOLS_BIN_DIR}/kubectl"
}

function tools::install::kind() {
    tools::export_path

    local bin="${TOOLS_BIN_DIR}/kind"
    if [[ -x "${bin}" ]] && "${bin}" version 2>/dev/null | grep -q "v${KIND_VERSION}\b"; then
        return 0
    fi

    local os=$(util::tools::os)
    local arch=$(util::tools::arch)
    local url="https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-${os}-${arch}"
    mkdir -p "${TOOLS_BIN_DIR}"

    echo "Installing kind from ${url}..."
    curl -sSL -o "${TOOLS_BIN_DIR}/kind" "${url}"
    chmod +x "${TOOLS_BIN_DIR}/kind"
}
