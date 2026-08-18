#!/usr/bin/env bash
# setup-podman-vm.sh
# Called automatically by create-kind.sh / install when Podman is detected.
# Prepares the Podman VM (macOS/Windows) for use with kind and NFS.

set -euo pipefail

if [ "$(uname -s)" = "Linux" ]; then
  echo "Running on Linux – Podman VM setup not needed (native Podman runtime)."
  echo "Loading NFS kernel modules directly on the host..."

  sudo modprobe nfs   2>/dev/null || echo "WARN: Could not load 'nfs' module"
  sudo modprobe nfsv3 2>/dev/null || echo "WARN: Could not load 'nfsv3' module"
  sudo modprobe nfsd  2>/dev/null || echo "WARN: Could not load 'nfsd' module"

  if grep -qE "^nfsd[[:space:]]" /proc/modules 2>/dev/null; then
    echo "  nfsd – confirmed in /proc/modules ✓"
  else
    echo "WARN:   nfsd not found in /proc/modules – NFS server may fail to start."
  fi

  echo "Linux NFS setup complete."
  exit 0
fi

PODMAN_MACHINE="${PODMAN_MACHINE:-podman-machine-default}"

if ! podman machine list --format '{{.Name}}' 2>/dev/null | grep -qxF "${PODMAN_MACHINE}"; then
  echo "Podman machine '${PODMAN_MACHINE}' not found – creating it (rootful, 4 CPU, 8 GB, 60 GB disk)..."
  podman machine init \
    --cpus 4 \
    --memory 8192 \
    --disk-size 60 \
    --rootful \
    "${PODMAN_MACHINE}"
fi

machine_state=$(podman machine inspect "${PODMAN_MACHINE}" --format '{{.State}}' 2>/dev/null || echo "unknown")
if [ "${machine_state}" = "running" ]; then
  echo "Podman machine '${PODMAN_MACHINE}' is already running."
else
  echo "Starting Podman machine '${PODMAN_MACHINE}' (state: ${machine_state})..."
  podman machine start "${PODMAN_MACHINE}"
  sleep 5
fi


# Helper
_vm_init_ssh() {
  local json
  json=$(podman machine inspect "${PODMAN_MACHINE}" 2>/dev/null) \
    || echo "ERROR: Cannot inspect Podman machine '${PODMAN_MACHINE}'."

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
  echo "VM SSH: ${VM_SSH_USER}@127.0.0.1:${VM_SSH_PORT}  key=${VM_SSH_KEY}"
}

vm_exec() {
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

echo "Loading NFS kernel modules in the Podman VM..."
vm_exec 'sudo modprobe nfs; sudo modprobe nfsv3; sudo modprobe nfsd; exit 0' \
  || echo "WARN: One or more NFS modprobe calls returned non-zero"

echo "Verifying NFS kernel support in the Podman VM..."

nfsd_in_proc=$(vm_exec 'grep -cE "^nfsd[[:space:]]" /proc/modules 2>/dev/null || echo 0')
nfsd_in_proc=$(echo "${nfsd_in_proc}" | tr -d '[:space:]')

if [ "${nfsd_in_proc:-0}" -gt 0 ]; then
  echo "  nfsd – confirmed in /proc/modules ✓"
elif vm_exec 'grep -q "nfsd" /proc/filesystems 2>/dev/null'; then
  echo "  nfsd – built into kernel, injecting synthetic /proc/modules entry..."
  vm_exec 'echo "nfsd 0 0 - Live 0x0000000000000000 (builtin)" | sudo tee -a /proc/modules > /dev/null'
  echo "  nfsd – synthetic entry injected ✓"
else
  vm_exec 'grep -iE "nfs" /proc/modules 2>/dev/null || echo "    (none)"'
  vm_exec 'find /lib/modules/$(uname -r) -name "*nfs*" 2>/dev/null | head -20 || echo "    (none found)"'
  echo "ERROR: The 'nfsd' kernel module is NOT available in the Podman VM.
  Fix: recreate the Podman machine:
    podman machine stop ${PODMAN_MACHINE}
    podman machine rm   ${PODMAN_MACHINE}
    make up"
fi

for mod in nfs nfsv3; do
  if vm_exec "grep -qE '^${mod}[[:space:]]' /proc/modules 2>/dev/null || test -d /sys/module/${mod} 2>/dev/null"; then
    echo "  ${mod} – OK ✓"
  else
    echo "WARN:  ${mod} – not confirmed"
  fi
done

vm_exec 'printf "nfs\nnfsv3\nnfsd\n" | sudo tee /etc/modules-load.d/nfs-kind.conf > /dev/null'
vm_exec 'printf "[Unit]\nDescription=Load NFS kernel modules for CF/kind\nDefaultDependencies=no\nAfter=systemd-modules-load.service\nBefore=network-pre.target\n\n[Service]\nType=oneshot\nRemainAfterExit=yes\nExecStart=/bin/sh -c \"modprobe nfs; modprobe nfsv3; modprobe nfsd; exit 0\"\n\n[Install]\nWantedBy=multi-user.target\n" | sudo tee /etc/systemd/system/nfs-modules-load.service > /dev/null'
vm_exec 'sudo systemctl daemon-reload && sudo systemctl enable nfs-modules-load.service'
echo "NFS module systemd service installed and enabled."

echo "Configuring inotify limits in the Podman VM..."
vm_exec 'printf "fs.inotify.max_user_instances = 8192\nfs.inotify.max_user_watches = 524288\n" | sudo tee /etc/sysctl.d/99-cf-kind.conf > /dev/null && sudo sysctl --system > /dev/null'

echo "Podman VM setup complete."

