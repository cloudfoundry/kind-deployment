#!/bin/sh

APPLICATION_YAML=${APPLICATION_YAML:-/application.yml}

if [ ! -f "/ssl/trust_store.jks" ]; then
    echo "Creating trust store from CA certificate"
    keytool -import -noprompt -trustcacerts -alias uaa_ca -file /ssl/ca.crt -keystore /tmp/trust_store.jks -storepass ${TRUST_STORE_PASSWORD}
    export TRUST_STORE_PATH=/tmp/trust_store.jks
fi

JAVA_OPTS="-Djava.security.egd=file:/dev/urandom"
JAVA_OPTS="$JAVA_OPTS -Djdk.tls.ephemeralDHKeySize=4096"
JAVA_OPTS="$JAVA_OPTS -Djdk.tls.namedGroups=\"secp384r1\""
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=${TRUST_STORE_PATH}"
JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStorePassword=${TRUST_STORE_PASSWORD}"
JAVA_OPTS="$JAVA_OPTS -Dspring.config.location=${APPLICATION_YAML}"

trap 'kill -TERM "$java_pid"' TERM INT

java $JAVA_OPTS -ea -jar /app/credhub.jar --management.server.port=9001 &
java_pid=$!

wait "$java_pid"
