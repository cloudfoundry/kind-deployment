# kind-deployment

This repository provides a simple and fast way to run Cloud Foundry locally. It enables developers to rapidly prototype, develop, and test new ideas in an inexpensive setup.

## Prerequisites

The following tools need to be installed:

- [`docker`](https://docs.docker.com/engine/install/) or [`podman`](https://podman.io/docs/installation) (v4.0 or higher)
- [`docker-compose`](https://docs.docker.com/compose/install) or [`podman-compose`](https://github.com/containers/podman-compose) (v1.0 or higher)
- [`kind`](https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries) (v0.31.0 or higher)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/#kubectl) (v1.35.1 or higher)
- `make`:
  - It should be already installed on MacOS and Linux.
  - For Windows installation see: <https://gnuwin32.sourceforge.net/packages/make.htm>

The container runtime is auto-detected. Set `CONTAINER_RUNTIME=docker` or `CONTAINER_RUNTIME=podman` to override.

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

## Podman Support

Podman is supported as a drop-in replacement for Docker. The runtime is detected automatically; no aliasing is required.

### macOS / Windows (Podman Desktop)

A Podman machine is created and configured automatically by `make up`. The machine is created in rootful mode with 4 CPUs, 8 GB RAM, and 60 GB disk. No manual configuration is needed.

### Linux (rootful Podman)

Rootful Podman is supported on Linux. The following kernel setting must be applied before running `make up` — either manually or via your system's sysctl configuration:

```bash
sudo sysctl -w fs.inotify.max_user_instances=512
```

This prevents inotify exhaustion under heavy workloads.

## ARM / Apple Silicon Limitations

The CF stack (`cflinuxfs4`) and all buildpacks are **x86-64 (amd64) only**. CF applications run inside `cflinuxfs4` containers, which are amd64 images and require x86 emulation on ARM hosts.

- **Docker Desktop on Apple Silicon:** Enable Rosetta emulation (Settings → General → Use Rosetta for x86_64/amd64 emulation). This is the recommended and well-tested path.
- **Podman on Apple Silicon:** The Podman machine is created with `--rootful` and runs under QEMU/Rosetta. Functional, but noticeably slower than Docker Desktop with Rosetta.
- **Linux ARM64:** Not supported. The `cflinuxfs4` stack image and pre-compiled buildpack zip files are amd64-only. CF app staging and execution will fail on a native ARM64 host without kernel-level x86 emulation (`binfmt_misc` with QEMU).

The CF platform components themselves (gorouter, diego, CAPI, etc.) are built for the local architecture, so control-plane operations are native-speed on ARM. Only the **application workload layer** (buildpacks, cflinuxfs4) is restricted to amd64.

## Unsupported Features

- Routing isolation segments are not fully feature complete since this relies on more than one gateway which is not possible to realize in a local kind setup (see [FAQ](./docs/faq.md))

## Read More Documentation

- [Local Development Guide](docs/local-development-guide.md)
- [FAQs](docs/faq.md)

## Contributing

Please check our [contributing guidelines](/CONTRIBUTING.md).

This project follows [Cloud Foundry Code of Conduct](https://www.cloudfoundry.org/code-of-conduct/)
