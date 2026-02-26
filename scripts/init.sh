#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

mkdir -p "${ROOT_DIR}/temp/certs"

CERTS_DIR="${ROOT_DIR}/temp/certs"
CONF_FILE="${ROOT_DIR}/certs/all-in-one.conf"

openssl genrsa -traditional -out "${CERTS_DIR}/ca.key" 4096
openssl req -x509 -key "${CERTS_DIR}/ca.key" -out "${CERTS_DIR}/ca.crt" -days 365 -noenc -subj "/CN=ca/O=ca" \
	-config "${CONF_FILE}" -extensions v3_ca > /dev/null 2>&1
openssl req -new -keyout "${CERTS_DIR}/all-in-one.key" -out "${CERTS_DIR}/all-in-one.csr" -noenc -config "${CONF_FILE}" > /dev/null 2>&1
openssl x509 -req -in "${CERTS_DIR}/all-in-one.csr" -CA "${CERTS_DIR}/ca.crt" -CAkey "${CERTS_DIR}/ca.key" -CAcreateserial \
	-out "${CERTS_DIR}/all-in-one.crt" -days 365 -copy_extensions copy > /dev/null 2>&1

rm -f "${CERTS_DIR}/ssh_key" "${CERTS_DIR}/ssh_key.pub"
ssh-keygen -t rsa -b 4096 -f "${CERTS_DIR}/ssh_key" -N "" > /dev/null 2>&1

echo "export BLOBSTORE_PASSWORD=$(openssl rand -hex 16)" > "${ROOT_DIR}/temp/secrets.sh"
echo "export DB_PASSWORD=$(openssl rand -hex 16)" >> "${ROOT_DIR}/temp/secrets.sh"
echo "export OAUTH_CLIENTS_SECRET=$(openssl rand -hex 16)" >> "${ROOT_DIR}/temp/secrets.sh"
echo "export DIEGO_SSH_CREDENTIALS=$(openssl rand -hex 16)" >> "${ROOT_DIR}/temp/secrets.sh"
echo "export CC_ADMIN_PASSWORD=$(openssl rand -hex 16)" >> "${ROOT_DIR}/temp/secrets.sh"
echo "export UAA_ADMIN_SECRET=$(openssl rand -hex 16)" >> "${ROOT_DIR}/temp/secrets.sh"
echo "export SSH_PROXY_KEY_FINGERPRINT=$(ssh-keygen -l -E md5 -f "${CERTS_DIR}/ssh_key.pub" | cut -d' ' -f2 | cut -d: -f2-)" >> "${ROOT_DIR}/temp/secrets.sh"

sed 's/^export //g' "${ROOT_DIR}/temp/secrets.sh" > "${ROOT_DIR}/temp/secrets.env"
