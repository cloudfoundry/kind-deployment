# Local Development Guide

This guide explains how to test local code changes in your kind cluster.

## 1. Build Local Image

The images are built in [cf-k8s-releases](https://github.com/cloudfoundry/cf-k8s-releases). For building the image with modified source code, please refer to th [local-development-guide](https://github.com/cloudfoundry/cf-k8s-releases/blob/main/docs/local-development-guide.md).

## 2. Load Image into kind

Make the locally built image available to your kind cluster:

```bash
kind load docker-image <image>:latest --name cfk8s
```

**Example:**

```bash
kind load docker-image gorouter:latest --name cfk8s
```

## 3. Use the Image

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
