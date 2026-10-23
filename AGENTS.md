# AGENTS.md

Guidance for humans and AI agents working in `kind-deployment`. For contribution process
(PR scope, raising issues, code of conduct) see [`CONTRIBUTING.md`](CONTRIBUTING.md); this
file covers how the repo is built and how to work in it effectively.

## What this repo is

`kind-deployment` stands up a full Cloud Foundry on a Kubernetes cluster you point it at.
It pulls the Helm charts published to `ghcr.io/cloudfoundry/helm` by
[`cf-k8s-releases`](https://github.com/cloudfoundry/cf-k8s-releases) and deploys them
alongside third-party charts (Istio, NATS, PostgreSQL, MinIO, a CNI).

It contains no application source code and builds no images: pure orchestration (a
`Makefile`, shell scripts, a Helmfile, value files, pinned tools, CI). It does not author
the CF component charts either — those are maintained in `cf-k8s-releases` and referenced
here only by version.

## Layout

- `Makefile` — entry point; every workflow is a target.
- `helmfile.yaml.gotmpl` — the deploy graph: repositories, releases, their order, hooks.
- `values.yaml.gotmpl` + `versions.yaml` — environment config and pinned versions.
- `scripts/` — the install steps the Makefile calls (certs/secrets, KinD, helmfile sync,
  buildpack upload, tests, pinned-tool installer, version sync).
- `assets/` — the `base-chart` and per-release value overrides.
- `.github/` — CI workflows, the reusable `setup-cf` action, renovate config.
- `bin/`, `temp/` — generated, gitignored (pinned tools; certs/secrets/kubeconfig).

## Running it

All workflows go through the `Makefile`:

```bash
make up         # create a KinD cluster, then init + install
make login      # wait for the API, then cf login as ccadmin
make bootstrap  # create test org/space, set feature flags, upload core buildpacks
make smoke      # run smoke tests
make cats       # run CF Acceptance Tests
make down       # delete the KinD cluster and remove temp/
```

`make up` is `create-kind init install`. For more granular control — or to deploy onto a
cluster you already have — run the steps yourself:

```bash
make init       # scripts/init.sh: generate certs, SSH keys, and random secrets into temp/
make install    # scripts/install.sh: source secrets + pinned tools, then `helmfile sync`
```

Set `CLUSTER_DOMAIN` to target a non-local cluster; any value other than the default
`127-0-0-1.nip.io` flips `localDeployment` off, which skips the KinD-only pieces (CNI
install, CoreDNS rewrite) and leaves that cluster to provide its own CNI, LoadBalancer, and
storage.

## The Helmfile

`helmfile.yaml.gotmpl` is the deploy graph. Its environment values are merged in order:
`values.yaml.gotmpl`, then `versions.yaml`, then anything in `ADDITIONAL_VALUES_FILES`
(comma-separated; last wins — this is the override hook, see README).

- **CNI is selectable** via the `CNI` env var (`cilium` default, or `calico`); the Helmfile
  swaps chart, namespace, and CRD/hook handling accordingly. Only installed for a local
  deployment (`localDeployment`).
- **Optional components** are gated by `installOptionalComponents`
  (`INSTALL_OPTIONAL_COMPONENTS`): `bosh-dns`, `cf-tcp-router`, `credhub`, `loggregator`,
  `nfsbroker`, `policy-agent`, `policy-server`, `routing-api`, `service-discovery-controller`.
- Per-release config overrides live in `assets/values/*.yaml`, referenced from the release's
  `values:` block.

## Versions

`versions.yaml` pins every deployed chart, buildpack, and stack; `scripts/tools.sh` pins the
CLI tools downloaded into `bin/`. Two update mechanisms:

- **`sync-cf-deployment-versions.py`** keeps the CF component chart versions in step with the
  latest `cloudfoundry/cf-deployment` release. It runs daily and opens a PR; its versions are
  **not** Renovate-managed, so hand-edits are overwritten on the next sync.
- **Renovate** updates everything carrying a `# renovate: dataSource=... depName=...` comment
  adjacent to the value (the CNIs, `policy-agent`, and the tool versions). Minor/patch
  updates automerge.

## CI

- `.github/workflows/kind-smoke.yaml` / `kind-cats.yaml` — stand up a real KinD cluster and
  run smoke / CATs against it.
- `.github/workflows/sync-cf-deployment-versions.yaml` — the daily version sync above.
- `.github/actions/setup-cf` — a composite action other repos use to provision a full CF on
  KinD inside their own workflow (see README for inputs). `setup-cf-tests` wraps it for this
  repo's test jobs.

## Local development

See [`docs/local-development-guide.md`](docs/local-development-guide.md) and
[`docs/faq.md`](docs/faq.md). Override any value without editing tracked files via
`ADDITIONAL_VALUES_FILES`:

```bash
ADDITIONAL_VALUES_FILES=./my-values.yaml make up
```

Podman users must alias it to `docker`/`docker-compose` — scripts call `docker` directly
(see README).
