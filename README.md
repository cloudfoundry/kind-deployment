# kind-deployment

This repository provides a simple and fast way to run Cloud Foundry locally. It enables developers to rapidly prototype, develop, and test new ideas in an inexpensive setup.

## Prerequisites

The following tools need to be installed:

- [`docker`](https://docs.docker.com/engine/install/)
- [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries) (v0.31.0 or higher)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl) (v1.35.1 or higher)
- `make`:
  - It should be already installed on MacOS and Linux.
  - For Windows installation see: <https://gnuwin32.sourceforge.net/packages/make.htm>

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

| environment variable    | default | component(s) to be installed                                           |
| ----------------------- | ------- | ---------------------------------------------------------------------- |
| `ENABLE_LOGGREGATOR`    | `true`  | Loggregator                                                            |
| `ENABLE_POLICY_SUPPORT` | `true`  | policy-serverver, policy-agent, bosh-dns, service-discovery-controller |
| `ENABLE_TCP_ROUTING`    | `true`  | cf-tcp-router, routing-api                                             |
| `ENABLE_NFS_VOLUME`     | `false` | nfsbroker                                                              |

## Unsupported Features

- Routing isolation segments are not fully feature complete since this relies on more than one gateway which is not possible to realize in a local kind setup (see [FAQ](./docs/faq.md))
- TCP isolation segments are not configurable yet

## Read More Documentation

- [Local Development Guide](docs/local-development-guide.md)
- [FAQs](docs/faq.md)

## Contributing

Please check our [contributing guidelines](/CONTRIBUTING.md).

This project follows [Cloud Foundry Code of Conduct](https://www.cloudfoundry.org/code-of-conduct/).
