# Domain Configuration

The domain for the Cloud Foundry deployment is now configurable via the `CF_DOMAIN` environment variable.

## Default Domain

By default, the deployment uses `127-0-0-1.nip.io` which works for local KinD deployments accessible at `127.0.0.1`.

## Custom Domain

To use a custom domain, set the `CF_DOMAIN` environment variable before running any deployment commands:

```bash
export CF_DOMAIN="my-custom-domain.com"
```

## Files That Use CF_DOMAIN

### Automatically Configured
- `scripts/upload_buildpacks.sh` - Uses `${CF_DOMAIN:-127-0-0-1.nip.io}` for file server URL
- `Makefile` login target - Uses `${CF_DOMAIN:-127-0-0-1.nip.io}` for API endpoint
- `helmfile.yaml.gotmpl` - Passes domain to Helm via `.Values.domain` (currently only MinIO blobstore)
- `values.yaml.gotmpl` - Exposes domain as a Helm value
- `.github/workflows/kind-cats.yaml` - Uses `${CF_DOMAIN}` in test URLs
- `.github/cats-config.tpl` - Uses `${CF_DOMAIN}` expansion for API, apps, and credhub domains
- `.github/smoke-config.tpl` - Uses `${CF_DOMAIN}` expansion for API and apps domain
- `.github/actions/setup-cf-tests/action.yaml` - Exports `CF_DOMAIN` before template processing

### Manual Configuration Required

The following files contain hardcoded domain references that should be updated if you're using a custom domain:

#### 1. `assets/gateway.yaml`
Istio Gateway configuration with hardcoded DNS names and hostnames:
- Lines 9-11: Certificate DNS names (`*.127-0-0-1.nip.io`, `*.apps.127-0-0-1.nip.io`, `*.blobstore.127-0-0-1.nip.io`)
- Lines 140, 147: Gateway listener hostnames
- Lines 160, 169: TLS hostnames for credhub and UAA
- Lines 229-230: HTTPRoute hostnames for blobstore

**Recommendation**: Template this file using Helm or use `envsubst` during deployment.

#### 2. Helm Release Values Files
The following Helm chart values files contain hardcoded domain references:
- `releases/log-cache/helm/values.yaml` - Lines 2, 18
- `releases/loggregator-agent/helm/values.yaml` - Line (syslog-binding-cache hostname)
- `releases/loggregator/helm/values.yaml` - Lines (doppler and log-stream hostnames)
- `releases/diego/helm/values.yaml` - (if any domain references)
- `releases/capi/helm/values.yaml` - (if any domain references)
- `releases/uaa/helm/values.yaml` - (if any domain references)
- `releases/cf-networking/helm/values.yaml` - (if any domain references)
- `releases/routing/helm/values.yaml` - (if any domain references)
- `releases/credhub/helm/values.yaml` - (if any domain references)

**Note**: These values files are typically managed as upstream Helm chart values. The recommended approach is to:
1. Create a `values-override.yaml` file that uses Helm templating
2. Pass the domain as a Helm value via `helmfile.yaml.gotmpl`
3. Reference `.Values.domain` in override values

**Current limitation**: Since these are local chart values (not overrides), they would need to be templated individually or passed via helmfile values overrides.

## Example Usage

### Local Development (Default)
```bash
make up
make login
```

### Custom Domain
```bash
export CF_DOMAIN="cf.example.com"
make up
make login
```

### CI/CD
Set `CF_DOMAIN` as an environment variable in your CI pipeline:
```yaml
env:
  CF_DOMAIN: "ci.cloudfoundry.example.com"
```

## Implementation Status

- ✅ Shell scripts (upload_buildpacks.sh)
- ✅ Makefile targets
- ✅ Helmfile global values
- ✅ GitHub Actions workflows
- ✅ Test configuration templates (.tpl files)
- ⚠️ Istio Gateway configuration (requires manual templating)
- ⚠️ Helm chart values files (requires override strategy)

## Future Improvements

1. Template `assets/gateway.yaml` using Helm or envsubst
2. Create a global Helm values override mechanism for release-specific domains
3. Add domain validation to the init script
4. Document DNS requirements for custom domains
