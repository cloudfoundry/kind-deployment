#!/usr/bin/env bash
# setup-podman-vm.sh
# Called automatically by create-kind.sh / install when Podman is detected.
# Prepares the Podman VM (macOS/Windows) for use with kind and NFS.
#
# On Linux, Podman runs natively (no VM) – this script is skipped.
#
# Environment variables:
#   PODMAN_MACHINE  – name of the Podman machine (default: podman-machine-default)

set -euo pipefail

log()  { echo "==> $*"; }
err()  { echo ""; echo "ERROR: $*" >&2; echo ""; exit 1; }
warn() { echo "WARN:  $*" >&2; }

# ---------------------------------------------------------------------------
# Skip VM setup on Linux (Podman runs natively, no machine abstraction)
# ---------------------------------------------------------------------------
if [ "$(uname -s)" = "Linux" ]; then
  log "Running on Linux – Podman VM setup not needed (native Podman runtime)."
  log "Loading NFS kernel modules directly on the host..."

  # Load NFS modules on the Linux host (for kind worker node containers)
  sudo modprobe nfs   2>/dev/null || warn "Could not load 'nfs' module"
  sudo modprobe nfsv3 2>/dev/null || warn "Could not load 'nfsv3' module"
  sudo modprobe nfsd  2>/dev/null || warn "Could not load 'nfsd' module"

  # Verify
  if grep -qE "^nfsd[[:space:]]" /proc/modules 2>/dev/null; then
    log "  nfsd – confirmed in /proc/modules ✓"
  else
    warn "  nfsd not found in /proc/modules – NFS server may fail to start."
  fi

  # On Linux, check if Podman is running rootless and warn about privileged ports
  if [ -z "${PODMAN_SOCK:-}" ] && [ ! -w /run/podman/podman.sock ] && [ -S "${XDG_RUNTIME_DIR}/podman/podman.sock" ]; then
    warn ""
    warn "Podman is running in ROOTLESS mode."
    warn "kind will FAIL to bind privileged ports (80, 443, 2222)."
    warn ""
    warn "Fix options:"
    warn "  1. Run this script with sudo: sudo -E make up"
    warn "  2. Or configure unprivileged port start:"
    warn "       echo 'net.ipv4.ip_unprivileged_port_start=80' | sudo tee -a /etc/sysctl.conf"
    warn "       sudo sysctl -p"
    warn ""
    err "Cannot proceed with rootless Podman – kind requires privileged ports."
  fi

  log "Linux NFS setup complete."
  exit 0
fi

# macOS/Windows only from here on
PODMAN_MACHINE="${PODMAN_MACHINE:-podman-machine-default}"

# ---------------------------------------------------------------------------
# 1. Ensure the Podman machine exists
# ---------------------------------------------------------------------------
if ! podman machine list --format '{{.Name}}' 2>/dev/null | grep -qxF "${PODMAN_MACHINE}"; then
  log "Podman machine '${PODMAN_MACHINE}' not found – creating it (rootful, 4 CPU, 8 GB, 60 GB disk)..."
  podman machine init \
    --cpus 4 \
    --memory 8192 \
    --disk-size 60 \
    --rootful \
    "${PODMAN_MACHINE}"
fi

# ---------------------------------------------------------------------------
# 2. Ensure the machine is running
# ---------------------------------------------------------------------------
machine_state=$(podman machine inspect "${PODMAN_MACHINE}" --format '{{.State}}' 2>/dev/null || echo "unknown")
if [ "${machine_state}" = "running" ]; then
  log "Podman machine '${PODMAN_MACHINE}' is already running."
else
  log "Starting Podman machine '${PODMAN_MACHINE}' (state: ${machine_state})..."
  podman machine start "${PODMAN_MACHINE}"
  sleep 5
fi

# ---------------------------------------------------------------------------
# Helper: run a shell command string inside the Podman VM via direct SSH.
#
# Usage:  vm_exec 'command; another command'
#
# We use the raw SSH binary (not podman machine ssh) with -T to avoid TTY
# allocation. Connection parameters are read from podman machine inspect.
# ---------------------------------------------------------------------------
_vm_init_ssh() {
  local json
  json=$(podman machine inspect "${PODMAN_MACHINE}" 2>/dev/null) \
    || err "Cannot inspect Podman machine '${PODMAN_MACHINE}'."

  VM_SSH_PORT=$(python3 -c "
import sys, json
d = json.loads('''${json}''')
m = d[0] if isinstance(d, list) else d
cfg = m.get('SSHConfig', m)
print(cfg.get('Port', 62522))
" 2>/dev/null || echo "62522")

  VM_SSH_USER=$(python3 -c "
import sys, json
d = json.loads('''${json}''')
m = d[0] if isinstance(d, list) else d
cfg = m.get('SSHConfig', m)
print(cfg.get('RemoteUsername', 'core'))
" 2>/dev/null || echo "core")

  VM_SSH_KEY=$(python3 -c "
import sys, json
d = json.loads('''${json}''')
m = d[0] if isinstance(d, list) else d
cfg = m.get('SSHConfig', m)
print(cfg.get('IdentityPath', ''))
" 2>/dev/null || echo "")

  export VM_SSH_PORT VM_SSH_USER VM_SSH_KEY
  log "VM SSH: ${VM_SSH_USER}@127.0.0.1:${VM_SSH_PORT}  key=${VM_SSH_KEY}"
}

vm_exec() {
  # Pass the command as a single SSH argument – no bash -c wrapper needed.
  # The remote login shell executes the string directly.
  ssh -T \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -o ConnectTimeout=15 \
    ${VM_SSH_KEY:+-i "${VM_SSH_KEY}"} \
    -p "${VM_SSH_PORT}" \
    "${VM_SSH_USER}@127.0.0.1" \
    "$1"
}

_vm_init_ssh

# ---------------------------------------------------------------------------
# 3. Load NFS kernel modules inside the Podman VM
# ---------------------------------------------------------------------------
log "Loading NFS kernel modules in the Podman VM..."
vm_exec 'sudo modprobe nfs; sudo modprobe nfsv3; sudo modprobe nfsd; exit 0' \
  || warn "One or more NFS modprobe calls returned non-zero"

# ---------------------------------------------------------------------------
# 4. Verify modules are visible in /proc/modules
# ---------------------------------------------------------------------------
log "Verifying NFS kernel support in the Podman VM..."

nfsd_in_proc=$(vm_exec 'grep -cE "^nfsd[[:space:]]" /proc/modules 2>/dev/null || echo 0')
nfsd_in_proc=$(echo "${nfsd_in_proc}" | tr -d '[:space:]')

if [ "${nfsd_in_proc:-0}" -gt 0 ]; then
  log "  nfsd – confirmed in /proc/modules ✓"
elif vm_exec 'grep -q "nfsd" /proc/filesystems 2>/dev/null'; then
  log "  nfsd – built into kernel, injecting synthetic /proc/modules entry..."
  vm_exec 'echo "nfsd 0 0 - Live 0x0000000000000000 (builtin)" | sudo tee -a /proc/modules > /dev/null'
  log "  nfsd – synthetic entry injected ✓"
else
  vm_exec 'grep -iE "nfs" /proc/modules 2>/dev/null || echo "    (none)"'
  vm_exec 'find /lib/modules/$(uname -r) -name "*nfs*" 2>/dev/null | head -20 || echo "    (none found)"'
  err "The 'nfsd' kernel module is NOT available in the Podman VM.
  Fix: recreate the Podman machine:
    podman machine stop ${PODMAN_MACHINE}
    podman machine rm   ${PODMAN_MACHINE}
    make up"
fi

for mod in nfs nfsv3; do
  if vm_exec "grep -qE '^${mod}[[:space:]]' /proc/modules 2>/dev/null || test -d /sys/module/${mod} 2>/dev/null"; then
    log "  ${mod} – OK ✓"
  else
    warn "  ${mod} – not confirmed"
  fi
done

# ---------------------------------------------------------------------------
# 5. Persist modules across VM reboots
# ---------------------------------------------------------------------------
vm_exec 'printf "nfs\nnfsv3\nnfsd\n" | sudo tee /etc/modules-load.d/nfs-kind.conf > /dev/null'
vm_exec 'printf "[Unit]\nDescription=Load NFS kernel modules for CF/kind\nDefaultDependencies=no\nAfter=systemd-modules-load.service\nBefore=network-pre.target\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/bin/sh -c \"modprobe nfs; modprobe nfsv3; modprobe nfsd; exit 0\"\n\n[Install]\nWantedBy=multi-user.target\n" | sudo tee /etc/systemd/system/nfs-modules-load.service > /dev/null'
vm_exec 'sudo systemctl daemon-reload && sudo systemctl enable nfs-modules-load.service'
log "NFS module systemd service installed and enabled."

# ---------------------------------------------------------------------------
# 6. Raise inotify limits
# ---------------------------------------------------------------------------
log "Configuring inotify limits in the Podman VM..."
vm_exec 'printf "fs.inotify.max_user_instances = 8192\nfs.inotify.max_user_watches = 524288\n" | sudo tee /etc/sysctl.d/99-cf-kind.conf > /dev/null && sudo sysctl --system > /dev/null'

log "Podman VM setup complete."

