#!/usr/bin/env bash

set -euo pipefail

# Parse arguments
FORCE=false
if [ "${1:-}" = "--force" ]; then
  FORCE=true
fi

mkdir -p temp/certs

# Generate CA certificate only if it doesn't exist or force flag is set
if [ ! -f temp/certs/ca.key ] || [ "$FORCE" = true ]; then
  echo "Generating CA certificate..."
  openssl genrsa -traditional -out temp/certs/ca.key 4096
  openssl req -x509 -key temp/certs/ca.key -out temp/certs/ca.crt -days 365 -nodes -subj "/CN=ca/O=ca" > /dev/null 2>&1
else
  echo "CA certificate already exists (use --force to regenerate)"
fi

# Generate SSH key only if it doesn't exist or force flag is set
if [ ! -f temp/certs/ssh_key ] || [ "$FORCE" = true ]; then
  echo "Generating SSH key..."
  ssh-keygen -t rsa -b 4096 -f temp/certs/ssh_key -N "" > /dev/null 2>&1
else
  echo "SSH key already exists (use --force to regenerate)"
fi

# Generate secrets file only if it doesn't exist or force flag is set
if [ ! -f temp/secrets.sh ] || [ "$FORCE" = true ]; then
  echo "Generating secrets..."
  cat > temp/secrets.sh <<EOF
export BLOBSTORE_PASSWORD=$(openssl rand -hex 16)
export DB_PASSWORD=$(openssl rand -hex 16)
export OAUTH_CLIENTS_SECRET=$(openssl rand -hex 16)
export DIEGO_SSH_CREDENTIALS=$(openssl rand -hex 16)
export CC_ADMIN_PASSWORD=$(openssl rand -hex 16)
export UAA_ADMIN_SECRET=$(openssl rand -hex 16)
export SSH_PROXY_KEY_FINGERPRINT=$(ssh-keygen -l -E md5 -f temp/certs/ssh_key.pub | cut -d' ' -f2 | cut -d: -f2-)
EOF
else
  echo "Secrets file already exists (use --force to regenerate)"
fi

echo "Initialization complete"
