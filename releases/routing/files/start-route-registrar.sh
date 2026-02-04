#!/bin/sh -e

# Merge all JSON files into one config and set the pod IP as host.
jq -s ". | add | .host = \"${POD_IP}\"" /etc/route-registrar-template/route-registrar.json > /tmp/route-registrar.json

echo "Launching with config:"
cat /tmp/route-registrar.json

exec /usr/local/bin/route-registrar -configPath /tmp/route-registrar.json
