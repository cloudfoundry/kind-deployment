FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /diego-release/src
WORKDIR /diego-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/bbs code.cloudfoundry.org/bbs/cmd/bbs

FROM alpine:latest

COPY --from=builder /usr/local/bin/bbs /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/bbs" ]
CMD [ "-config", "/bbs/bbs.json" ]
