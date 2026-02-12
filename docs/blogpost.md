## Setting up a Local Cloud Foundry Playground in under 10 Minutes

I want to show you how easy it is to install Cloud Foundry locally. Whether you're using this setup to test something on your machine, showcase a feature, or simply learn how Cloud Foundry works, doesn't really matter.

Instead of using the traditional way, utilizing BOSH and virtual machines, this installation deploys all the same familiar Cloud Foundry components (UAA, Diego, CAPI, etc.) in a fully containerized environment without reimplementing anything. It simply changes how these existing components are installed and orchestrated.

### Starting Point

My local laptop is a `MacBook` with 16 GB of RAM and an M2 processor (8 cores). That should be more than powerful enough to run Cloud Foundry on `kind` (https://github.com/cloudfoundry/kind-deployment). I'm using Docker Desktop v4.59.1 but it also works with Docker Engine on Linux.

For those unfamiliar, `kind` ([Kubernetes in Docker](https://kind.sigs.k8s.io/)) is a tool for running local Kubernetes clusters using Docker containers as nodes. It's perfect for development and testing scenarios like this.

I already have the required tools installed (see https://github.com/cloudfoundry/kind-deployment?tab=readme-ov-file#prerequisites), so I can directly start.

### Installation

The installation is straightforward and hidden behind a single make target:

```bash
make up
```

But let's take a closer look at what actually happens...

It starts by creating a local kind cluster prepared to host our Cloud Foundry installation. All dependencies are installed in the local cluster (database, NATS, blobstore ...). If you want to dig into it, check out [`helmfile.yaml.gotmpl`](https://github.com/cloudfoundry/kind-deployment/blob/main/helmfile.yaml.gotmpl).

Once the cluster is prepared, the installation of the Cloud Foundry components begins: `uaa`, `locket`, `diego` and others - all sound very familiar. Only `k8s-rep` sounds somewhat new.

And it's true, basically all components are deployed without any changes. Just the installation method changed, they're installed with Helm instead of BOSH. The only exception to that is `rep` (`k8s-rep`), that leverages the new version of the [`garden.Client`](https://github.com/cloudfoundry/garden/blob/main/client.go) provided by the [`k8s-garden-client`](https://github.com/cloudfoundry/k8s-garden-client).

After about 5 minutes, the installation is complete. The speed depends on your CPU and internet connection, at least for the first run — but I'll get to that later.

### Before We Begin

Before we actually try out the Cloud Foundry installation, we need to set it up: creating an org, a space, uploading buildpacks, etc. Fortunately, there's also a simple make target to get you started. But first, we need to log in:

```bash
make login
make bootstrap
```

The `make login` command targets the local Cloud Foundry API endpoint and authenticates you as an admin user. The `make bootstrap` command then performs several initialization tasks:

- Creates a default organization and space
- Uploads commonly used buildpacks (Node.js, Ruby, Java, etc.)
- Enables necessary feature flags

Looking at the output, I can see several buildpacks being uploaded and configured. We should be ready to go now.

_Note:_ It uses classic buildpacks, but it would work exactly the same with Cloud Native Buildpacks.

### Trying It Out

For convenience, there's already an example app in the repo, so I can directly try pushing it.

```bash
cf push -f examples/hello-js/manifest.yaml
```

The familiar Cloud Foundry staging process begins: the buildpack is detected, dependencies are downloaded, the app is compiled, and finally a droplet is created and deployed. The output looks very familiar, showing all the usual steps.

Once deployed, the app behaves just like it would on any traditional Cloud Foundry installation. I can access it via its route, check logs with `cf logs`, and SSH into the container with `cf ssh`. Everything works exactly as expected. The developer experience is identical to a BOSH-deployed landscape.

### Cleanup

If I want to free up resources, I can easily tear down the kind cluster with:

```bash
make down
```

But the next time I install it, it will be significantly faster. Remember those registries that were set up at the very beginning? They're used as "pull-through" caches for all images and use volumes to persist them. So the next run will already have the images locally and won't need to download them again. This speeds up the installation significantly, so that `make up` might only take 2 minutes, depending on your local CPU.

### Summary

With `kind-deployment`, you can easily and quickly install a local Cloud Foundry environment. It uses Helm instead of BOSH, but the Cloud Foundry experience is the same, with the exception of the `garden.Client` used. This shouldn't make a difference for most use cases.

This setup is ideal for:

- Developing and debugging Cloud Foundry applications
- Learning Cloud Foundry without needing access to a full cluster
- Running integration tests in CI/CD pipelines

The entire environment runs locally, giving you full control and the ability to experiment freely. Whether you're a Cloud Foundry newcomer or an experienced operator, having a local playground makes development much more efficient.
