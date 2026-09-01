# OpenTelemetry Collector

The optional OpenTelemetry Collector runs as a sidecar in every
`forwarder-agent` DaemonSet Pod. Each forwarder sends CF logs, metrics, and
traces over mTLS to its colocated collector at `127.0.0.1:4317`.

## Enable the collector

Put this configuration in a Helmfile values file:

```yaml
otelCollector:
  enabled: true
  exporter:
    endpoint: ""
```

Pass the file through `ADDITIONAL_VALUES_FILES` (or the
`additional-values-files` input of the `setup-cf` action). For example:

```bash
ADDITIONAL_VALUES_FILES="$PWD/otel-collector-values.yaml" make up
```

For the action, pass an absolute path:

```yaml
with:
  additional-values-files: ${{ github.workspace }}/otel-collector-values.yaml
```

## Verify forwarding

without an external endpoint, each collector uses its detailed debug exporter, 
then inspect the collector sidecars:

```bash
export KUBECONFIG="$PWD/temp/kubeconfig"
kubectl -n cf-system logs daemonset/forwarder-agent -c otel-collector \
  --all-pods=true --prefix=true \
  | grep -E 'ResourceLogs?|ResourceMetrics'
```

Check the forwarders for TLS, retry, or connection failures:

```bash
kubectl -n cf-system logs daemonset/forwarder-agent -c forwarder-agent \
  --all-pods=true --prefix=true \
  | grep -Ei '\[OTEL COLLECTOR CLIENT\].*(retry|error|fail|refused|unavailable)'
```

No output from the second command indicates that no matching errors were found.

## Forward to an external local collector

To test the sidecars' OTLP exporter, start another collector outside kind:

```bash
docker run --detach --name otel-collector-outside-kind \
  --publish 4317:4317 \
  --volume "$PWD/docs/otel-collector-local-config.yaml:/etc/otel/config.yaml:ro" \
  otel/opentelemetry-collector-k8s:latest \
  --config=/etc/otel/config.yaml

docker exec cfk8s-control-plane \
  sh -c "ip route | awk '/default/ {print \$3; exit}'"
```

Set `otelCollector.exporter.endpoint` to the printed host address and port
`4317` (here `172.18.0.1`):

```yaml
otelCollector:
  enabled: true
  exporter:
    endpoint: "172.18.0.1:4317"
```

Redeploy and follow the external collector output:

```bash
ADDITIONAL_VALUES_FILES="$PWD/otel-collector-values.yaml" make install
docker logs -f otel-collector-outside-kind
```

The external endpoint uses insecure transport and is intended only for local
development.
