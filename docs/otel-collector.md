# OpenTelemetry Collector

Set `INSTALL_OTEL_COLLECTOR=true` when creating or updating the deployment:

```bash
INSTALL_OTEL_COLLECTOR=true make up
```

This deploys the upstream `open-telemetry/opentelemetry-collector` Helm chart as a standalone `otel-collector` Pod in `cf-system`. The forwarder agent discovers the OTLP gRPC port from its downstream registration and connects to the `otel-collector` Service on port `4317` using mTLS.

Without an export endpoint, the collector writes received telemetry to its debug exporter. To test forwarding to another local collector, run the following from the repository root:

```bash
docker run --detach --name otel-collector \
  --publish 4317:4317 \
  --volume "$PWD/docs/otel-collector-local-config.yaml:/etc/otel/config.yaml:ro" \
  otel/opentelemetry-collector-k8s:latest \
  --config=/etc/otel/config.yaml

make create-kind
OTEL_COLLECTOR_ADDRESS="$(docker exec cfk8s-control-plane \
  sh -c "ip route | awk '/default/ {print \$3; exit}'")"

INSTALL_OTEL_COLLECTOR=true \
OTEL_COLLECTOR_EXPORT_ENDPOINT="${OTEL_COLLECTOR_ADDRESS}:4317" \
make up

docker logs -f otel-collector
```

The optional export endpoint is configured without TLS and is intended only for local development.

## Verify forwarding

Confirm that the standalone collector receives CF logs and metrics:

```bash
export KUBECONFIG="$PWD/temp/kubeconfig"
kubectl -n cf-system logs deployment/otel-collector \
  | grep -E 'ResourceLogs|ResourceMetrics'
```

Check the forwarder logs for connection, TLS, or retry failures:

```bash
kubectl -n cf-system logs deployment/forwarder-agent -c forwarder-agent \
  | grep -Ei 'otel-collector:4317|tls|retry|error'
```
