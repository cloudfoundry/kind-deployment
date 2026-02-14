FROM --platform=$BUILDPLATFORM python:3@sha256:151ab3571dad616bb031052e86411e2165295c7f67ef27206852203e854bcd12 AS builder

ARG TARGETOS TARGETARCH
ARG CF_DEPLOYMENT_VERSION

COPY --from=files . .
RUN pip install -r requirements.txt && python get-compiled-releases.py ${CF_DEPLOYMENT_VERSION}

FROM nginx:1.27@sha256:6784fb0834aa7dbbe12e3d7471e69c290df3e6ba810dc38b34ae33d3c1c05f7d

COPY --from=builder /tmp/final /fileserver
