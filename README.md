# kind-deployment

This repository provides a simple and fast way to run Cloud Foundry locally. It enables developers to rapidly prototype, develop, and test new ideas in an inexpensive setup.

## Prerequisites

The following tools need to be installed:

- [`docker`](https://docs.docker.com/engine/install/) or [podman](https://podman.io/docs/installation)
- [`docker-compose`](https://docs.docker.com/compose/install) or [podman-compose](https://github.com/containers/podman-compose)
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

### Custom Helmfile values

Set `ADDITIONAL_VALUES_FILES` environment variable to a comma-separated list of [Helmfile values](https://helmfile.readthedocs.io/en/latest/#environment-values) files. They are merged last, so they can override any value in `values.yaml.gotmpl` (domains, CNI, chart versions, etc.).

```bash
ADDITIONAL_VALUES_FILES=./my-values.yaml make up
```

## Using the `setup-cf` GitHub Action

This repository ships a composite action at `.github/actions/setup-cf` that provisions a full Cloud Foundry environment on a KinD cluster inside a GitHub Actions workflow. After it completes, the generated credentials from `temp/secrets.env` are exported into `$GITHUB_ENV`, so later steps can use the CF CLI directly.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: cloudfoundry/kind-deployment/.github/actions/setup-cf@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - run: cf push -f examples/hello-js/manifest.yaml
```

Inputs (all optional):

- `isolated-cell` (boolean, default `false`): add an isolated worker cell for routing isolation segment tests.
- `install-optional-components` (boolean, default `true`): install optional CF components.
- `cf-cli-version` (string, default `8.19.0`): CF CLI version to install.
- `github-token` (string): GitHub API token, used when `use-latest-versions` is enabled to avoid rate limiting.
- `ref` (string, default `main`): kind-deployment branch, tag or commit SHA that is checked out and deployed. Set it to the same commit as the action's `@<sha>` to get a fully pinned setup.
- `use-latest-versions` (boolean, default `false`): sync to the latest `develop` versions of cf-deployment before deploying.

## Unsupported Features

- Routing isolation segments are not fully feature complete since this relies on more than one gateway which is not possible to realize in a local kind setup (see [FAQ](./docs/faq.md))

## Read More Documentation

- [Local Development Guide](docs/local-development-guide.md)
- [FAQs](docs/faq.md)

## Contributing

Please check our [contributing guidelines](/CONTRIBUTING.md).

This project follows [Cloud Foundry Code of Conduct](https://www.cloudfoundry.org/code-of-conduct/).
