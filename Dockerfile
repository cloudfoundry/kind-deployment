# renovate: datasource=docker depName=alpine
FROM alpine:3.21@sha256:c3f8e73fdb79deaebaa2037150150191b9dcbfba68b4a46d70103204c53f4709

# renovate: datasource=github-releases depName=kubernetes-sigs/kind
ARG KIND_VERSION=v0.31.0
# renovate: datasource=github-releases depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=v1.35.1
# renovate: datasource=github-releases depName=helmfile/helmfile
ARG HELMFILE_VERSION=v1.3.2
# renovate: datasource=github-releases depName=helm/helm
ARG HELM_VERSION=v4.1.1
# renovate: datasource=github-releases depName=cloudfoundry/cli
ARG CF_CLI_VERSION=v8.17.0

RUN apk add --no-cache \
    bash \
    curl \
    docker-cli \
    docker-cli-compose \
    jq \
    make \
    openssh-keygen \
    openssl

ARG TARGETARCH

RUN curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${TARGETARCH}" -o /usr/local/bin/kind \
    && chmod +x /usr/local/bin/kind

RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" | tar xz -C /tmp \
    && mv /tmp/linux-${TARGETARCH}/helm /usr/local/bin/helm \
    && rm -rf /tmp/linux-${TARGETARCH}

RUN curl -fsSL "https://github.com/helmfile/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION#v}_linux_${TARGETARCH}.tar.gz" | tar xz -C /tmp \
    && mv /tmp/helmfile /usr/local/bin/helmfile \
    && rm -rf /tmp/LICENSE /tmp/README*

RUN CF_ARCH=$([ "${TARGETARCH}" = "amd64" ] && echo "x86-64" || echo "${TARGETARCH}") \
    && curl -fsSL "https://github.com/cloudfoundry/cli/releases/download/${CF_CLI_VERSION}/cf8-cli_${CF_CLI_VERSION#v}_linux_${CF_ARCH}.tgz" | tar xz -C /tmp \
    && mv /tmp/cf8 /usr/local/bin/cf \
    && rm -rf /tmp/LICENSE /tmp/NOTICE

WORKDIR /workspace

COPY . .

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["make"]
