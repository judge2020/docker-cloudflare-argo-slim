FROM judge2020/cloudflare-argo:latest

ENTRYPOINT [ "./cloudflared", "login" ]
