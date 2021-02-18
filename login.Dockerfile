FROM ghcr.io/judge2020/cloudflared:latest

ENTRYPOINT [ "./cloudflared", "login" ]
