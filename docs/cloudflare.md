# Cloudflare and HTTPS

The wallet requires HTTPS for public use. Configure HTTPS before you use the stack outside testnet evaluation.

## Configure the origin

Set the public hostname in `.env`:

```dotenv
CADDY_SITE=wallet.example.com
```

Point the hostname to the server. Keep the Cloudflare proxy disabled until Caddy obtains the first public certificate.

Start the stack and make sure that direct HTTPS works. Then enable the Cloudflare proxy.

The Caddy configuration trusts only the Cloudflare networks that were published on August 27, 2026. It uses strict proxy parsing and the `CF-Connecting-IP` header.

Before each release, compare the configured networks with the official [IPv4](https://www.cloudflare.com/ips-v4/) and [IPv6](https://www.cloudflare.com/ips-v6/) lists.

## Configure Cloudflare

Use SSL/TLS mode `Full (strict)`. Do not use `Flexible` mode.

Permit WebSocket connections. The Blockbook live API uses `/websocket`.

Do not cache these paths:

- `/mainnet*`
- `/testnet*`
- `/api*`
- `/websocket`
- `/sendtx*`

The two Sapling parameter files can use a long public cache. Keep the wallet HTML cache short so that releases replace it promptly.

Apply rate limits to RPC submission, signed-transaction submission, and expensive address queries. Do not expose the node RPC port through Cloudflare.

After Caddy obtains its certificate, restrict origin ports `80` and `443` with the server firewall. Permit only the current Cloudflare networks.

This firewall rule prevents direct requests from bypassing Cloudflare controls. Keep SSH and other administrative access restricted to the operator network.
