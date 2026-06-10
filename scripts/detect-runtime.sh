#!/usr/bin/env bash
# detect-runtime.sh
# Auto-detects the available container runtime (Docker or Podman).
# Source this file – do NOT execute it directly.
#
#   source "$(dirname "$0")/detect-runtime.sh"
#
# Exports:
#   CONTAINER_RUNTIME  – the CLI command to use ("docker" or "podman")
#   COMPOSE_CMD        – e.g. "docker compose" or "podman-compose"
#   IS_PODMAN          – "true" or "false"
#
# Detection strategy (in order):
#   1. Honour explicit CONTAINER_RUNTIME env override.
#   2. If 'podman' binary exists → Podman.
#   3. If 'docker' binary exists → Docker (even if it is a Podman socket shim).
#      Use CONTAINER_RUNTIME=podman to force Podman when both are present.
#   4. Neither found → error.
#
# NOTE: We intentionally do NOT call 'docker info' / 'podman info' here
# because the Podman machine may not be running yet at detection time.
# The machine is started later by setup-podman-vm.sh.

if [ -n "${CONTAINER_RUNTIME:-}" ]; then
  # Respect explicit caller override
  if [ "${CONTAINER_RUNTIME}" = "podman" ]; then
    IS_PODMAN="true"
  else
    IS_PODMAN="false"
  fi
elif command -v podman &>/dev/null; then
  CONTAINER_RUNTIME="podman"
  IS_PODMAN="true"
elif command -v docker &>/dev/null; then
  CONTAINER_RUNTIME="docker"
  IS_PODMAN="false"
else
  echo "ERROR: Neither 'podman' nor 'docker' binary found in PATH." >&2
  echo "       Install Podman Desktop (https://podman-desktop.io) or Docker Desktop." >&2
  exit 1
fi

if [ "${IS_PODMAN}" = "true" ]; then
  # kind requires this provider hint when using Podman
  export KIND_EXPERIMENTAL_PROVIDER=podman
fi

# Prefer standalone podman-compose over 'podman compose' sub-command.
# 'podman compose' may delegate to the docker-compose plugin and fail
# without a Docker daemon present.
if [ "${IS_PODMAN}" = "true" ] && command -v podman-compose &>/dev/null; then
  COMPOSE_CMD="podman-compose"
else
  COMPOSE_CMD="${CONTAINER_RUNTIME} compose"
fi

export CONTAINER_RUNTIME IS_PODMAN COMPOSE_CMD
