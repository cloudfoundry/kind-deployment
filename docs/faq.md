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
