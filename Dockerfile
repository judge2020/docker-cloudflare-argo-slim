FROM ubuntu:18.04
LABEL maintainer="Hunter Ray <me@judge.sh>"

RUN apt-get update \
 && apt-get install -y --no-install-recommends wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN wget -O cloudflared.tgz https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.tgz \
 && tar -xzvf cloudflared.tgz \
 && rm cloudflared.tgz \
 && chmod +x cloudflared

# Credit to github.com/martinandert for this script (https://git.io/JfLKZ)
 RUN ldd cloudflared | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'

FROM scratch
WORKDIR /
COPY --from=0 /deps /
COPY --from=0 /cloudflared /
COPY --from=0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["./cloudflared"]
