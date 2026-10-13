# OpenTelemetry Collector

To enable the collector, put this in a Helmfile values file and use it via `ADDITIONAL_VALUES_FILES` (or the `additional-values-files` input of the `setup-cf` action):

```yaml
otelCollector:
  enabled: true
  exporter:
    endpoint: ""
```

For example, if the configuration is stored in `otel-collector-values.yaml`, run locally:

```bash
ADDITIONAL_VALUES_FILES="$PWD/otel-collector-values.yaml" make up
```

When using the `setup-cf` action, pass the absolute path to the same file:

```yaml
with:
  additional-values-files: ${{ github.workspace }}/otel-collector-values.yaml
```

This deploys the upstream `open-telemetry/opentelemetry-collector` Helm chart as a standalone `otel-collector` Pod in `cf-system`. The forwarder agent discovers the OTLP gRPC port from its downstream registration and connects to the `otel-collector` Service on port `4317` using mTLS.

## Verify forwarding

Without an external endpoint configured, confirm from the repository root that the standalone collector receives CF logs and metrics:

```bash
export KUBECONFIG="$PWD/temp/kubeconfig"
kubectl -n cf-system logs deployment/otel-collector \
  | grep -E 'ResourceLogs?|ResourceMetrics'
```

Check the forwarder logs for connection, TLS, or retry failures:

```bash
kubectl -n cf-system logs deployment/forwarder-agent -c forwarder-agent \
  | grep -Ei '\[OTEL COLLECTOR CLIENT\].*(retry|error|fail|refused|unavailable)'
```

## Configure external endpoint

Without an export endpoint, the collector writes received telemetry to its debug exporter. To test forwarding to another local collector running outside kind, run the following from the repository root:

```bash
docker run --detach --name otel-collector-outside-kind \
  --publish 4317:4317 \
  --volume "$PWD/docs/otel-collector-local-config.yaml:/etc/otel/config.yaml:ro" \
  otel/opentelemetry-collector-k8s:latest \
  --config=/etc/otel/config.yaml

make create-kind
docker exec cfk8s-control-plane \
  sh -c "ip route | awk '/default/ {print \$3; exit}'"
```

Set `otelCollector.exporter.endpoint` in the additional values file to the printed address and port `4317`, while keeping the collector enabled. For example:

```yaml
otelCollector:
  enabled: true
  exporter:
    endpoint: "172.18.0.1:4317"
```

Then deploy the configuration and follow the outside collector's logs:

```bash
ADDITIONAL_VALUES_FILES="$PWD/otel-collector-values.yaml" make up
docker logs -f otel-collector-outside-kind
```

The external endpoint is configured without TLS and is intended only for local development.
