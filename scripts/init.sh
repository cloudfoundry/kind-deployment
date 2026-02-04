#!/usr/bin/env bash

set -euo pipefail

mkdir -p temp/certs

openssl genrsa -traditional -out temp/certs/ca.key 4096
openssl req -x509 -key temp/certs/ca.key -out temp/certs/ca.crt -days 365 -nodes -subj "/CN=ca/O=ca" > /dev/null 2>&1

ssh-keygen -t rsa -b 4096 -f temp/certs/ssh_key -N "" > /dev/null 2>&1

echo "export BLOBSTORE_PASSWORD=$(openssl rand -hex 16)" >> temp/secrets.sh
echo "export DB_PASSWORD=$(openssl rand -hex 16)" >> temp/secrets.sh
echo "export OAUTH_CLIENTS_SECRET=$(openssl rand -hex 16)" >> temp/secrets.sh
echo "export DIEGO_SSH_CREDENTIALS=$(openssl rand -hex 16)" >> temp/secrets.sh
echo "export CC_ADMIN_PASSWORD=$(openssl rand -hex 16)" >> temp/secrets.sh
echo "export UAA_ADMIN_SECRET=$(openssl rand -hex 16)" >> temp/secrets.sh

echo "export SSH_PROXY_KEY_FINGERPRINT=$(ssh-keygen -l -E md5 -f temp/certs/ssh_key.pub | cut -d' ' -f2 | cut -d: -f2-)" >> temp/secrets.sh
