# Local Development Guide

This guide explains how to test local code changes in your kind cluster.

## 1. Make Code Changes

Edit your source code locally in your project directory (e.g., routing-release or other relevant Cloud Foundry project).

## 2. Build Image

Build a Docker image with your local changes:

```bash
docker buildx bake <image> --set <image>.contexts.src=<path-to-local-source>
```

**Example:**

```bash
docker buildx bake gorouter --set gorouter.contexts.src=/Users/user/routing-release/src
```

This creates an image tagged as `<image>:latest` (e.g., `gorouter:latest`) in your local Docker daemon.

<details>

  <summary>View all available images</summary>

  To see all buildable images:

  ```bash
  docker buildx bake --print
  ```

</details>

## 3. Load Image into kind

Make the locally built image available to your kind cluster:

```bash
kind load docker-image <image>:latest --name cfk8s
```

**Example:**

```bash
kind load docker-image gorouter:latest --name cfk8s
```

## 4. Use the Image

Update the deployment or daemonset to use your local image:

```bash
kubectl edit deployment <component-name>
```

**Example:**

```bash
kubectl edit deployment gorouter
```

Modify the image and pull policy:

```yaml
spec:
  template:
    spec:
      containers:
      - name: gorouter
        image: gorouter:latest
        imagePullPolicy: IfNotPresent  # Important: prevents pulling from registry
```

After save and exit the relevant pods will be restarted automatically.
