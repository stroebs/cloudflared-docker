# cloudflared-docker
Custom Docker images for cloudflared

Cloudflare does not have an image for 32-bit ARM (arm/v7 or arm/v5) in their [cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) repository. This was created specifically for RB4011 with an ARM 32bit AL21400 processor but should work fine on any other 32bit ARM CPU, including older ARMv5 devices.

The image is available at [stroebs/cloudflared](https://hub.docker.com/r/stroebs/cloudflared) and is built once a month on the 1st of the month. The image is roughly 24MB thus is space conscious for MikroTik devices with limited storage.

| Tag | Platform | Base |
| --- | --- | --- |
| `latest` | `linux/arm/v7` + `linux/arm/v5` (multi-arch manifest) | as below |
| `arm32v7` | `linux/arm/v7` | `gcr.io/distroless/base-debian13:nonroot` (same as upstream) |
| `arm32v5` | `linux/arm/v5` | `scratch` + CA certificates (distroless has no arm/v5 build) |

`latest` resolves to the right variant automatically; use `arm32v5` / `arm32v7` if your runtime cannot pick a variant from a multi-arch manifest.

## Building

`cloudflared` is cross-compiled from upstream `master` with `GOARCH=arm GOARM=7|5` (no emulated compiler), so the build works on any host:

```bash
git clone https://github.com/cloudflare/cloudflared.git cloudflared
docker buildx build --platform linux/arm/v5 -t cloudflared:arm32v5 .
```

## Running in MikroTik RouterOS

To run this image in RouterOS is trivial. Assuming you've already done the prelimiary steps [in the MikroTik documentation](https://help.mikrotik.com/docs/display/ROS/Container), it's a one-line command to get the `cloudflared` tunnel created:

```bash
/container/add \
    remote-image=stroebs/cloudflared:latest \
    start-on-boot=yes \
    name="cloudflared" \
    check-certificate=no \
    interface=veth1 \
    cmd="tunnel --no-autoupdate run --token <token>"
# Note that check-certificate=no ignores the Docker Registry certificate
```

The container needs to be started once extracted using Winbox Containers menu or using the terminal:
```bash
/container/start cloudflared
```
