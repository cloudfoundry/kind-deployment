#!/usr/bin/env bash
# detect-runtime.sh
# Auto-detects the available container runtime (Docker or Podman).
# Source this file – do NOT execute it directly.
#
#   source "$(dirname "$0")/detect-runtime.sh"
#
# Exports:
#   CONTAINER_RUNTIME  – the CLI command to use ("docker" or "podman")
#   COMPOSE_CMD        – e.g. "docker compose" or "podman compose"
#   IS_PODMAN          – "true" or "false"
#
# Detection strategy (in order):
#   1. Honour explicit CONTAINER_RUNTIME env override.
#   2. If 'podman' binary exists   → Podman  (alias docker=podman counts too)
#   3. If 'docker' binary exists and is NOT Podman → Docker
#   4. Neither found → error.
#
# NOTE: We intentionally do NOT call 'docker info' / 'podman info' here
# because the Podman machine may not be running yet at detection time.
# The machine is started later by setup-podman-vm.sh.

# Allow explicit override
if [ -n "${CONTAINER_RUNTIME:-}" ]; then
  IS_PODMAN="false"
  [ "${CONTAINER_RUNTIME}" = "podman" ] && IS_PODMAN="true"
else
  # Prefer podman binary when it exists
  if command -v podman &>/dev/null; then
    CONTAINER_RUNTIME="podman"
    IS_PODMAN="true"
  elif command -v docker &>/dev/null; then
    CONTAINER_RUNTIME="docker"
    # Check if 'docker' is actually Podman (socket compat or renamed binary)
    if docker version 2>/dev/null | grep -qi 'podman'; then
      IS_PODMAN="true"
    else
      IS_PODMAN="false"
    fi
  else
    echo "ERROR: Neither 'podman' nor 'docker' binary found in PATH." >&2
    echo "       Install Podman Desktop (https://podman-desktop.io) or Docker Desktop." >&2
    exit 1
  fi
fi

if [ "${IS_PODMAN}" = "true" ]; then
  # kind requires this provider hint when using Podman
  export KIND_EXPERIMENTAL_PROVIDER=podman
fi

# Compose sub-command
COMPOSE_CMD="${CONTAINER_RUNTIME} compose"

export CONTAINER_RUNTIME IS_PODMAN COMPOSE_CMD
