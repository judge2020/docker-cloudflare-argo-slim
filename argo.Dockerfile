FROM judge2020/cloudflared:latest


ENTRYPOINT ["./cloudflared", "tunnel", "--no-autoupdate"]
