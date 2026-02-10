# kind-deployment

This repository provides a simple and fast way to run Cloud Foundry locally. It enables developers to rapidly prototype, develop, and test new ideas in an inexpensive setup.

## Prerequisites

You need to install following tools:

- kind: <https://kind.sigs.k8s.io/docs/user/quick-start/#installing-from-release-binaries>
- kubectl: <https://kubernetes.io/docs/tasks/tools/#kubectl>
- helm: <https://helm.sh/docs/intro/install#through-package-managers>
- make:
  - It should be alreay installed on MacOS and Linux.
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

| environment variable | default | component(s) to be installed |
|---------------------|---------|---------------------------|
| ENABLE_LOGGREGATOR  | true    | Loggregator |
| ENABLE_POLICY_SUPPORT | true  | poicy-serverver, policay-agent, bosh-dns, discovery-service |
| ENABLE_NFS_VOLUME | false | NFS volume service |


## Read More Documentation

- [Local Development Guide](docs/local-development-guide.md)
- [FAQs](docs/faq.md)
