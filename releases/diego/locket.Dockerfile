FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /diego-release/src
WORKDIR /diego-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/locket code.cloudfoundry.org/locket/cmd/locket

FROM alpine:latest

COPY --from=builder /usr/local/bin/locket /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/locket" ]
CMD [ "-config", "/locket/locket.json" ]
