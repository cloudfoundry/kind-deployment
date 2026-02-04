FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /capi-release/src
WORKDIR /capi-release/src/code.cloudfoundry.org/cc-uploader

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/cc-uploader code.cloudfoundry.org/cc-uploader/cmd/cc-uploader

FROM alpine:latest

COPY --from=builder /usr/local/bin/cc-uploader /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/cc-uploader" ]
CMD [ "-configPath", "/cc-uploader/cc-uploader.json" ]
