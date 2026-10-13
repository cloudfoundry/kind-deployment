# OpenTelemetry Collector

Set `INSTALL_OTEL_COLLECTOR=true` when creating or updating the deployment:

```bash
INSTALL_OTEL_COLLECTOR=true make up
```

This deploys the upstream `open-telemetry/opentelemetry-collector` Helm chart as a standalone `otel-collector` Pod in `cf-system`. The forwarder agent discovers the OTLP gRPC port from its downstream registration and connects to the `otel-collector` Service on port `4317` using mTLS.

Without an export endpoint, the collector writes received telemetry to its debug exporter. To forward telemetry to another local OTLP endpoint instead, set `OTEL_COLLECTOR_EXPORT_ENDPOINT` to its `host:port`:

```bash
INSTALL_OTEL_COLLECTOR=true \
OTEL_COLLECTOR_EXPORT_ENDPOINT=172.18.0.1:4317 \
make up
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
