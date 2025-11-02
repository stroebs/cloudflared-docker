# cloudflared-docker
Custom Docker images for cloudflared

Cloudflare does not have an image for arm/v7 in their [cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) repository. Since I want to run cloudflared on my MikroTik router (RB4011 with an ARM 32bit AL21400 processor), I need an `armv7` image, so I created one here.  

The image is available at [stroebs/cloudflared](https://hub.docker.com/r/stroebs/cloudflared) and is built once a month on the 1st of the month.

## Running in MikroTik RouterOS

To run this image in RouterOS is trivial. Assuming you've already done the prelimiary steps [in the MikroTik documentation](https://help.mikrotik.com/docs/display/ROS/Container), it's a one-line command to get the `cloudflared` tunnel running:

```bash
/container/add remote-image=stroebs/cloudflared:latest cmd="tunnel --no-autoupdate run --token <token>" interface=veth1
```
