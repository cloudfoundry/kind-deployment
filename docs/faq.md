# Frequently Asked Questions

## What are the minimum memory requirements?

Docker Desktop requires at least **8 GB of RAM** allocated.

Configuration: Docker Desktop → Settings → Resources.

## Which Docker Virtual Machine Manager should I use on macOS?

We recommend using the **Apple Virtualization framework** with **Rosetta for x86_64/amd64 emulation on Apple Silicon**. This has proven to be reliable environment.

Configuration: Docker Desktop → Settings → General → Choose Virtualization Framework → Enable Rosetta.

## How long does a deployment take?

This highly depends on your CPU. Also the first run has to download all images and they are cached for all subsequent runs. This is of course affected by your internet connection.

So for the first run 5-20min and after that 2-7min are realistic.

## How can I delete local image caches?

To cache images we run registry containers with persistent docker volumes locally.
While the registry containers are deleted when running `make down`, one still has to delete the persistent volumes.

To delete the cache volumes one by one execute:

```bash
# List the existing caches
docker volume ls --filter name=^cache_
# Delete the volumes with
docker volume rm <volume_name>
```

To delete all cache volumes at once, you can run:

```bash
docker volume ls --filter name=^cache_ -q | xargs docker volume rm
```

## How can I run the installation without image caching?

```bash
DISABLE_CACHE=true make up
```

## Why aren't routing isolation segments feature complete?

In `kind`, it is not possible to have two or more gateways with different IP addresses. This is necessary so that a gorouter assigned to an isolated segment cannot be reached by a spoofed host header (see `cf-acceptance-test` for routing isolation segments [one](https://github.com/cloudfoundry/cf-acceptance-tests/blob/e5fe6a71964d8b9d243df649567ef905a50ddc21/routing_isolation_segments/routing_isolation_segments.go#L147-L154) and [two](https://github.com/cloudfoundry/cf-acceptance-tests/blob/e5fe6a71964d8b9d243df649567ef905a50ddc21/routing_isolation_segments/routing_isolation_segments.go#L101-L110)). It is still possible to deploy and assign multiple instances of `gorouter` to different segments and these are correctly isolated, but the gateway is not.

## How can I solve inotify issues?

Running CF app containers inside Docker requires sufficient inotify limits on the **host**. Without this,
e.g. the Envoy sidecar proxy will crash with exit code 134 (SIGABRT).

Check current values:
```bash
sudo sysctl fs.inotify.max_user_instances fs.inotify.max_user_watches
```

Apply immediately (no reboot needed):
```bash
sudo sysctl -w fs.inotify.max_user_instances=512
sudo sysctl -w fs.inotify.max_user_watches=524288
```

Make permanent:
```bash
echo -e "fs.inotify.max_user_instances=512\nfs.inotify.max_user_watches=524288" \
  | sudo tee /etc/sysctl.d/99-inotify.conf
```
