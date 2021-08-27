# docker-cloudflared

This repository has been archived as Cloudflare has released their own docker hub version. This README includes the previous instructions but adapted for the official image. The old image will stay up and the docs/files are available on the `master` branch.


## Argo Tunnel

Image: `cloudflare/cloudflared` (You **MUST** obtain [the newest] tag [from here](https://hub.docker.com/r/cloudflare/cloudflared/tags?page=1&ordering=last_updated) as CF does not tag `latest`).

### Prerequisites

If you don't include a PEM nor a TUNNEL_HOSTNAME (but you still must have an (empty) mount point at /root/.cloudflared), you may use this for free - cloudflared will automatically generated you a hostname at [trycloudflare.com](https://developers.cloudflare.com/argo-tunnel/trycloudflare/).

And, for now, a certificate file (`.pem`) [needs to be obtained via `cloudflared tunnel login`](https://developers.cloudflare.com/argo-tunnel/quickstart/#step-3-login-to-your-cloudflare-account) *before* using the container. This can be done on any computer, or by running the following script:

```
docker run --rm -v "$PWD/config:/root/.cloudflared" --user 0 cloudflare/cloudflared:2021.8.3 login
```

You may change the host bind mount (`$PWD/config`) to any directory or volume where the certificate (`cert.pem`) will be outputted once you authenticate.

For security, after you do this, you may optionally edit `cert.pem` and remove the tunnel token section - this is not required for Argo Tunnel to connect, only for issuing new private keys for hostnames.

### Docker file permissions

Since Cloudflared runs using a different user by default, it doesn't run as root which complicates storing your certificate. You have some options for persisting your Cloudflared origin certificate's folder (/home/nonroot/.cloudflared):


- **Strict permissions**: create a linux user, grant it permission to your hosts' bind mount, and run your docker with the user, eg `--user {USER_ID}` or, in a compose file, `user: {USERNAME}`
- **Open permissions**: you make the directory and change its permission set to `777` (which allowed any linux user to read the file)
- **Return to root**: you may specify `--user 0` / `user: root` to run as root once more, the commands here are listed as so since it's the simplest.

To use a named volume instead of a bind mount, you can run `docker volume create unique_volume_name_cfdata` and specify that as the source for your volume mounts, however you must still change permissions for thos volume mount by doing any of the above. If you are modifying permissions, the directory of your volume is the output of `docker volume inspect unique_volume_name_cfdata -f '{{.Mountpoint}}'`.


### Configuration

You may either use environment variables, args, or a config.yml within your bind mount. Recommended environment variables:

- `TUNNEL_HOSTNAME`: The hostname/subdomain of the public-facing zone registered with Cloudflare
- `TUNNEL_URL`: The backend URL server you want to dig the tunnel to, probably on your local/Docker network

Or, you may create config.yml in your bind mount.

You may configure other variables via the env vars listed at https://developers.cloudflare.com/argo-tunnel/reference/arguments/.

...and your `.pem` file (the login certificate from Cloudflare) needs to be mounted to `/root/.cloudflared/cert.pem` on the Argo container, as shown in the example.

### Usage

```
docker run -d \
           -e "TUNNEL_HOSTNAME=test.example.com" \
           -e "TUNNEL_URL=http://127.0.0.1:8080" \
           -v "$PWD/config:/root/.cloudflared" \
           --user 0 \
           cloudflare/cloudflared:2021.8.3 tunnel
```

Docker Compose:

```
version: '3'

services:
    nginx:
        image: nginx
    
    cloudflared:
        image: cloudflare/cloudflared:2021.8.3
        user: root
        command: tunnel
        environment: 
            - TUNNEL_HOSTNAME=test.judge.sh
            - TUNNEL_URL=http://nginx:80
        volumes:
            - './config:/root/.cloudflared' # bind mount with cert.pem in it
```

Compose, but docker swarm:

```
version: '3'

services:
    nginx:
        image: nginx
    
    cloudflared:
        image: cloudflare/cloudflared:2021.8.3
        user: root
        environment: 
            - TUNNEL_HOSTNAME=test.judge.sh
            - TUNNEL_URL=http://nginx:80
        secrets:
            - source: cloudflare_cert.pem
              target: /root/.cloudflared/cert.pem

secrets:
    cloudflare_cert.pem:
        file: ./config/cert.pem
```
