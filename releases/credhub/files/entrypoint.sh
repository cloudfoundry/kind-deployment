#!/bin/sh

APPLICATION_YAML=${APPLICATION_YAML:-/app/config/application.yml}
SERVER_CA_CERT_PATH=${SERVER_CA_CERT_PATH:-/etc/ssl/ca/tls.crt}
SERVER_CA_PRIVATE_KEY_PATH=${SERVER_CA_PRIVATE_KEY_PATH:-/etc/ssl/ca/tls.key}
POSTGRES_CA_PATH=${POSTGRES_CA_PATH:-/etc/ssl/certs/postgres/ca.crt}
TRUST_STORE_PATH=${TRUST_STORE_PATH:-/app/stores/trust_store.jks}
KEY_STORE_PATH=${KEY_STORE_PATH:-/app/stores/key_store.jks}
UAA_CA_PATH=${UAA_CA_PATH:-/etc/ssl/uaa/ca.crt}

setup_tls_key_store() {
    cp "${SERVER_CA_CERT_PATH}" server_ca_cert.pem
    cp "${SERVER_CA_PRIVATE_KEY_PATH}" server_ca_private.pem

    cat > server.cnf <<EOF
[v3_ca]
subjectKeyIdentifier=hash
subjectAltName="${SUBJECT_ALTERNATIVE_NAMES}"
EOF

    echo "Generating a key store for the certificate the server presents during TLS"
    # generate keypair for the server cert
    openssl genrsa -out server_key.pem 2048

    echo "Create CSR for the server cert"
    openssl req -new -sha256 -key server_key.pem -subj "/CN=localhost" -out server.csr

    echo "Generate server certificate signed by our CA"
    openssl x509 -req -in server.csr -sha384 -CA server_ca_cert.pem -CAkey server_ca_private.pem \
        -CAcreateserial -out server.pem -extensions v3_ca -extfile server.cnf

    echo "Create a .p12 file that contains both server cert and private key"
    openssl pkcs12 -export -in server.pem -inkey server_key.pem \
        -out server.p12 -name cert -password pass:changeit

    echo "Import signed certificate into the keystore"
    keytool -importkeystore \
        -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass changeit \
        -deststorepass "${KEY_STORE_PASSWORD}" -destkeypass "${KEY_STORE_PASSWORD}" \
        -destkeystore "${KEY_STORE_PATH}" -alias cert

    rm server.p12 server.csr server_ca_cert.pem server_ca_private.pem server_key.pem server.cnf server.pem
}

rm -rf /app/store && mkdir -p /app/stores

if [ ! -f ${SERVER_CA_CERT_PATH} ] || [ ! -f ${SERVER_CA_PRIVATE_KEY_PATH} ]; then
    echo "Server CA certificate or private key not found, exiting"
    exit 1
fi

echo "Creating trust store from CA certificate"
keytool -import -noprompt -trustcacerts -alias ca -file ${SERVER_CA_CERT_PATH} -keystore ${TRUST_STORE_PATH} -storepass ${TRUST_STORE_PASSWORD}

if [ -f ${POSTGRES_CA_PATH} ]; then
    echo "Adding Postgres CA certificate to trust store"
    keytool -import -noprompt -trustcacerts -alias postgres_ca -file ${POSTGRES_CA_PATH} -keystore ${TRUST_STORE_PATH} -storepass ${TRUST_STORE_PASSWORD}
fi

if [ -f ${UAA_CA_PATH} ]; then
    echo "Adding UAA CA certificate to trust store"
    keytool -import -noprompt -trustcacerts -alias uaa_ca -file ${UAA_CA_PATH} -keystore ${TRUST_STORE_PATH} -storepass ${TRUST_STORE_PASSWORD}
fi

setup_tls_key_store

JAVA_OPTS="-Djava.security.egd=file:/dev/urandom"
JAVA_OPTS="$JAVA_OPTS -Djdk.tls.ephemeralDHKeySize=4096"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=${TRUST_STORE_PATH}"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStorePassword=${TRUST_STORE_PASSWORD}"
JAVA_OPTS="$JAVA_OPTS -Dspring.config.location=${APPLICATION_YAML}"

trap 'kill -TERM "$java_pid"' TERM INT

java $JAVA_OPTS -ea -jar /app/credhub.jar --management.server.port=9001 &
java_pid=$!

wait "$java_pid"
