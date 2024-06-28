# cloudflared-docker
Custom Docker images for cloudflared

Cloudflare does not have an image for arm/v7 in their [cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) repository. Since I want to run cloudflared on my MikroTik router, I need an `armv7` image, so I created one here.  

The image is available at [stroebs/cloudflared](https://hub.docker.com/r/stroebs/cloudflared) and is at the time of writing only built on-demand.
