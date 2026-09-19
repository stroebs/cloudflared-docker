# syntax=docker/dockerfile:1

# Builds cloudflared for 32-bit ARM (linux/arm/v7 and linux/arm/v5).
#
# The upstream Dockerfile compiles inside a QEMU-emulated container and uses a
# distroless base, neither of which is available for arm/v5. Instead we
# cross-compile on the build host (Go handles GOARCH=arm GOARM=5|7 natively)
# and pick a runtime base per target variant.

# use a builder image for building cloudflared on the host platform
FROM --platform=$BUILDPLATFORM golang:1.26.8 AS builder
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOPROXY=https://proxy.golang.org|direct \
    # the CONTAINER_BUILD envvar is used set github.com/cloudflare/cloudflared/metrics.Runtime=virtual
    # which changes how cloudflared binds the metrics server
    CONTAINER_BUILD=1

WORKDIR /go/src/github.com/cloudflare/cloudflared/

# Download dependencies in their own layer so source-only changes reuse it.
COPY cloudflared/go.mod cloudflared/go.sum ./
RUN go mod download

# copy upstream sources (checked out into ./cloudflared by the workflow)
COPY cloudflared/ .

# compile cloudflared; TARGETVARIANT is "v7"/"v5", the Makefile wants GOARM=7/5
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH TARGET_ARM=${TARGETVARIANT#v} make cloudflared

# assemble the bits a scratch-based runtime needs: CA bundle, nonroot user, home and tmp
RUN mkdir -p /rootfs/etc/ssl/certs /rootfs/home/nonroot /rootfs/tmp \
    && cp /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/ \
    && echo 'nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin' > /rootfs/etc/passwd \
    && echo 'nonroot:x:65532:' > /rootfs/etc/group \
    && chown 65532:65532 /rootfs/home/nonroot \
    && chmod 1777 /rootfs/tmp

# arm/v7 runtime: distroless base with glibc, same as upstream
FROM gcr.io/distroless/base-debian13:nonroot AS runtime-v7

# arm/v5 runtime: distroless does not publish arm/v5, so build the equivalent
# from scratch (cloudflared is statically linked with CGO_ENABLED=0)
FROM scratch AS runtime-v5
COPY --from=builder /rootfs/ /
ENV HOME=/home/nonroot \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

# select the runtime stage matching the target platform variant
FROM runtime-${TARGETVARIANT}

LABEL org.opencontainers.image.source="https://github.com/cloudflare/cloudflared"

# copy our compiled binary
COPY --from=builder --chown=65532:65532 /go/src/github.com/cloudflare/cloudflared/cloudflared /usr/local/bin/

# run as nonroot user (65532 is distroless' nonroot uid)
USER 65532:65532

# command / entrypoint of container
ENTRYPOINT ["cloudflared", "--no-autoupdate"]
CMD ["version"]
