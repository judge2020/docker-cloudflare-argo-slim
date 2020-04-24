# docker-cloudflared

This is a slim container (~20mb, the size of Cloudflared for linux) for the tool Cloudflared, which includes [Argo tunnel](https://www.cloudflare.com/products/argo-tunnel/). Image testing is generally only done for Argo Tunnel, but the `latest` tag for this image is the basic `cloudflared` with no extra args, and should work for most other usages.

This image uses a multi-stage Docker build to pull the latest cloudflared, determine the necessary dependencies needed, and only copy those (plus ca-certificates). See [the Dockerfile](Dockerfile).

Image: `judge2020/cloudflared:latest`



## Argo Tunnel

Image: `judge2020/cloudflared:argo`

### Prerequisites

If you don't include a PEM nor a TUNNEL_HOSTNAME (but you still must have an (empty) mount point at /.cloudflared), you may use this for free with a automatically generated hostname at [trycloudflare.com](https://developers.cloudflare.com/argo-tunnel/trycloudflare/).

And, for now, a certificate file (`.pem`) [needs to be obtained via `cloudflared tunnel login`](https://developers.cloudflare.com/argo-tunnel/quickstart/#step-3-login-to-your-cloudflare-account) *before* using the container. This can be done on any computer, or by running the following script:

```
docker run --rm -v "$PWD/config:/.cloudflared" judge2020/cloudflared:login
```

You may change the host bind mount (`$PWD/config`) to any directory or volume where the certificate (`cert.pem`) will be outputted once you authenticate.


### Configuration

The following environment variables are required:

- `TUNNEL_HOSTNAME`: The hostname/subdomain of the public-facing zone registered with Cloudflare
- `TUNNEL_URL`: The backend URL server you want to dig the tunnel to, probably on your local/Docker network

You may configure other variables via the env vars listed at https://developers.cloudflare.com/argo-tunnel/reference/arguments/.

...and your `.pem` file (the login certificate from Cloudflare) needs to be mounted to `/.cloudflared/cert.pem` on the Argo container, as shown in the example.

### Usage

```
docker run -d \
           -e "TUNNEL_HOSTNAME=test.example.com" \
           -e "TUNNEL_URL=http://127.0.0.1:8080" \
           -v "$PWD/config:/.cloudflared" \
           judge2020/cloudflared:argo
```

Docker Compose:

```
version: '3'

services:
    nginx:
        image: nginx
    
    cloudflared:
        image: judge2020/cloudflared:argo
        environment: 
            - TUNNEL_HOSTNAME=test.judge.sh
            - TUNNEL_URL=http://nginx:80
        volumes:
            - './config:/.cloudflared' # bind mount with cert.pem in it
```

Compose, but docker swarm:

```
version: '3'

services:
    nginx:
        image: nginx
    
    cloudflared:
        image: judge2020/cloudflared:argo
        environment: 
            - TUNNEL_HOSTNAME=test.judge.sh
            - TUNNEL_URL=http://nginx:80
        secrets:
            - source: cloudflare_cert.pem
              target: /.cloudflared/cert.pem

secrets:
    cloudflare_cert.pem:
        file: ./config/cert.pem
```
