#!/usr/bin/env bash

set -euo pipefail

mkdir -p temp/certs

OPENSSL="docker run --rm -v $(pwd)/temp/certs:/certs alpine/openssl"
SSH_KEYGEN="docker run --rm -v $(pwd)/temp/certs:/certs --entrypoint /usr/bin/ssh-keygen linuxserver/openssh-server"

$OPENSSL genrsa -traditional -out /certs/ca.key 4096
$OPENSSL req -x509 -key /certs/ca.key -out /certs/ca.crt -days 365 -nodes -subj "/CN=ca/O=ca" > /dev/null 2>&1

$SSH_KEYGEN -t rsa -b 4096 -f /certs/ssh_key -N "" > /dev/null 2>&1

echo "export BLOBSTORE_PASSWORD=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export DB_PASSWORD=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export OAUTH_CLIENTS_SECRET=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export DIEGO_SSH_CREDENTIALS=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export CC_ADMIN_PASSWORD=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export UAA_ADMIN_SECRET=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export SSH_PROXY_KEY_FINGERPRINT=$($SSH_KEYGEN -l -E md5 -f /certs/ssh_key.pub | cut -d' ' -f2 | cut -d: -f2-)" >> temp/secrets.sh

sed 's/^export //g' temp/secrets.sh > temp/secrets.env
