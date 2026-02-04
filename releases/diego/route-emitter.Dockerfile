FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /diego-release/src
WORKDIR /diego-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/route-emitter code.cloudfoundry.org/route-emitter/cmd/route-emitter

FROM alpine:latest

COPY --from=builder /usr/local/bin/route-emitter /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/route-emitter" ]
CMD [ "-config", "/route-emitter/route-emitter.json" ]
