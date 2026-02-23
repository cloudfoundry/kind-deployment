FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

RUN apk add --no-cache curl

COPY --from=root . /capi-release
WORKDIR /capi-release

RUN STORAGE_CLI_RELEASE_VERSION=$(sed -n 's/.*storage_cli_version="\([^"]*\)".*/\1/p' packages/storage-cli/packaging) && \
    curl https://github.com/cloudfoundry/storage-cli/releases/download/v${STORAGE_CLI_RELEASE_VERSION}/storage-cli-${STORAGE_CLI_RELEASE_VERSION}-linux-amd64 -L -o /usr/local/bin/storage-cli
RUN chmod +x /usr/local/bin/storage-cli

FROM alpine:latest

COPY --from=builder /usr/local/bin/storage-cli /
