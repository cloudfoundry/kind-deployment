# kind-deployment

This repository provides a simple and fast way to run Cloud Foundry locally. It enables developers to rapidly prototype, develop, and test new ideas in an inexpensive setup.

## Prerequisites

- [Docker](https://docs.docker.com/engine/install/) (with Docker Compose), alternatives like colima or podman may also work.
- [`cf` CLI](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html) (v8.17.0+)

All other tools (kind, kubectl, helm, helmfile) are bundled in the installer container.

## Run the Installation

```bash
make up
```

## Access and Bootstrap CloudFoundry

```bash
# Login via CF CLI and create a test space
make login

# Upload Java, Node, Go, and Binary buildpacks
# 'make bootstrap-complete' would upload all buildpacks
make bootstrap
```

## Deploy a Sample Application

```bash
cf push -f examples/hello-js/manifest.yaml
```

## Delete the Installation

```bash
make down
```

## Configuration

You can configure the installation by setting following environment variables:

| Environment Variable | Default | Description |
|---------------------|---------|-------------|
| `ENABLE_LOGGREGATOR` | `true` | Install Loggregator |
| `ENABLE_POLICY_SUPPORT` | `true` | Install policy-server, policy-agent, bosh-dns, service-discovery-controller |
| `ENABLE_TCP_ROUTING` | `true` | Install cf-tcp-router, routing-api |
| `ENABLE_NFS_VOLUME` | `false` | Install nfsbroker |
| `DISABLE_CACHE` | `false` | Disable registry pull-through caches |
| `DOCKER_SOCKET` | auto-detected | Path to Docker socket (override if auto-detection fails) |

Example:

```bash
ENABLE_NFS_VOLUME=true make up
```

## Additional Commands

| Command | Description |
|---------|-------------|
| `make shell` | Open a development shell (mounts local source code for development/testing) |
| `make build-installer` | Build the installer container without running it |

## Unsupported Features

- Routing isolation segments are not fully feature complete since this relies on more than one gateway which is not possible to realize in a local kind setup (see [FAQ](./docs/faq.md))

## Read More Documentation

- [Local Development Guide](docs/local-development-guide.md)
- [FAQs](docs/faq.md)

## Contributing

Please check our [contributing guidelines](/CONTRIBUTING.md).

This project follows [Cloud Foundry Code of Conduct](https://www.cloudfoundry.org/code-of-conduct/).
