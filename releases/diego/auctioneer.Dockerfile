FROM --platform=$BUILDPLATFORM golang:1-alpine AS builder

ARG TARGETOS TARGETARCH

COPY --from=src . /diego-release/src
WORKDIR /diego-release/src/code.cloudfoundry.org

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /usr/local/bin/auctioneer code.cloudfoundry.org/auctioneer/cmd/auctioneer

FROM alpine:latest

COPY --from=builder /usr/local/bin/auctioneer /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/auctioneer" ]
CMD [ "-config", "/auctioneer/auctioneer.json" ]
