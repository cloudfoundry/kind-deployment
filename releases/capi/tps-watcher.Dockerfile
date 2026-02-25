FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /capi-release/src
WORKDIR /capi-release/src/code.cloudfoundry.org/tps

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o tps-watcher code.cloudfoundry.org/tps/cmd/tps-watcher

FROM gcr.io/distroless/static:latest

COPY --from=builder /capi-release/src/code.cloudfoundry.org/tps/tps-watcher /usr/local/bin/tps-watcher

ENTRYPOINT [ "/usr/local/bin/tps-watcher" ]
CMD [ "-configPath", "/tps-watcher/tps-watcher.json" ]
