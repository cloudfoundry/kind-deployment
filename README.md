# kind-deployment

This repository provides a simple and fast way to run Cloud Foundry locally. It enables developers to rapidly prototype, develop, and test new ideas in an inexpensive setup.

## Prerequisites

The following tools need to be installed:

- [`docker`](https://docs.docker.com/engine/install/) or [podman](https://podman.io/docs/installation)
- [`docker-compose`](https://docs.docker.com/compose/install) or [podman-compose](https://github.com/containers/podman-compose)
- [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries) (v0.31.0 or higher)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl) (v1.35.1 or higher)
- `make`:
  - It should be already installed on MacOS and Linux.
  - For Windows installation see: <https://gnuwin32.sourceforge.net/packages/make.htm>

> [!IMPORTANT]  
> Please ensure that your Podman setup is configured as an alias for Docker, as this project relies on Docker commands. You can achieve this by executing `sudo ln -s /opt/podman/bin/podman /usr/local/bin/docker` and `sudo ln -s /opt/homebrew/bin/podman-compose /usr/local/bin/docker-compose` on Mac OS X.

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

You can configure the installation by setting the environment variable `INSTALL_OPTIONAL_COMPONENTS=false` to leave out these optional components:

`bosh-dns`, `cf-tcp-router`, `credhub`, `loggregator`, `nfsbroker`, `policy-agent`, `policy-server`, `routing-api`, `service-discovery-controller`

## Unsupported Features

- Routing isolation segments are not fully feature complete since this relies on more than one gateway which is not possible to realize in a local kind setup (see [FAQ](./docs/faq.md))

## Read More Documentation

- [Local Development Guide](docs/local-development-guide.md)
- [FAQs](docs/faq.md)

## Contributing

Please check our [contributing guidelines](/CONTRIBUTING.md).

This project follows [Cloud Foundry Code of Conduct](https://www.cloudfoundry.org/code-of-conduct/).
