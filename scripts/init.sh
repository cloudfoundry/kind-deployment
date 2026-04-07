#!/usr/bin/env bash

set -euo pipefail

mkdir -p temp/certs

# Auto-detect Docker or Podman
source "$(dirname "$0")/detect-runtime.sh"

OPENSSL="${CONTAINER_RUNTIME} run --rm -v $(pwd)/temp/certs:/certs -v $(pwd)/certs/all-in-one.conf:/all-in-one.conf alpine/openssl"
SSH_KEYGEN="${CONTAINER_RUNTIME} run --rm -v $(pwd)/temp/certs:/certs --entrypoint /usr/bin/ssh-keygen linuxserver/openssh-server"

$OPENSSL genrsa -traditional -out /certs/ca.key 4096
$OPENSSL req -x509 -key /certs/ca.key -out /certs/ca.crt -days 365 -noenc -subj "/CN=ca/O=ca" \
	-config /all-in-one.conf -extensions v3_ca > /dev/null 2>&1
$OPENSSL req -new -keyout /certs/all-in-one.key -out /certs/all-in-one.csr -noenc -config /all-in-one.conf > /dev/null 2>&1
$OPENSSL x509 -req -in /certs/all-in-one.csr -CA /certs/ca.crt -CAkey /certs/ca.key -CAcreateserial \
	-out /certs/all-in-one.crt -days 365 -copy_extensions copy > /dev/null 2>&1

rm -f temp/certs/ssh_key temp/certs/ssh_key.pub
$SSH_KEYGEN -t rsa -b 4096 -f /certs/ssh_key -N "" > /dev/null 2>&1

echo "export BLOBSTORE_PASSWORD=$($OPENSSL rand -hex 16)" > temp/secrets.sh
echo "export DB_PASSWORD=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export OAUTH_CLIENTS_SECRET=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export DIEGO_SSH_CREDENTIALS=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export CC_ADMIN_PASSWORD=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export UAA_ADMIN_SECRET=$($OPENSSL rand -hex 16)" >> temp/secrets.sh
echo "export SSH_PROXY_KEY_FINGERPRINT=$($SSH_KEYGEN -l -E md5 -f /certs/ssh_key.pub | cut -d' ' -f2 | cut -d: -f2-)" >> temp/secrets.sh

sed 's/^export //g' temp/secrets.sh > temp/secrets.env
