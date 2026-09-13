#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
caddyfile="$repo_root/gateway/Caddyfile"

if [[ ! -f "$caddyfile" ]]; then
    printf 'Missing gateway/Caddyfile.\n' >&2
    exit 1
fi

require_pattern() {
    local pattern=$1
    if ! rg -q -- "$pattern" "$caddyfile"; then
        printf 'Missing gateway rule: %s\n' "$pattern" >&2
        return 1
    fi
}

require_pattern "\\{\\\$CADDY_SITE"
require_pattern '^:8081'
require_pattern 'admin off'
require_pattern 'trusted_proxies static'
require_pattern 'trusted_proxies_strict'
require_pattern 'client_ip_headers CF-Connecting-IP X-Forwarded-For'
require_pattern '173\.245\.48\.0/20'
require_pattern '2c0f:f248::/32'
require_pattern 'path /testnet\*'
require_pattern 'reverse_proxy rpc-bridge:8080'
require_pattern '@mainnetDisabled path /mainnet\*'
require_pattern 'respond @mainnetDisabled 404'
require_pattern 'path /api\* /websocket'
require_pattern 'reverse_proxy blockbook:9130'
require_pattern 'path /wallet$'
require_pattern 'handle_path /wallet/\*'
require_pattern 'reverse_proxy wallet:80'
require_pattern 'Cross-Origin-Embedder-Policy.*require-corp'
require_pattern 'Cross-Origin-Opener-Policy.*same-origin'
require_pattern 'X-Content-Type-Options.*nosniff'
require_pattern 'X-Frame-Options.*DENY'
require_pattern 'Strict-Transport-Security.*max-age=31536000'
require_pattern "Content-Security-Policy.*default-src 'self'"
require_pattern "frame-ancestors 'none'"
require_pattern "object-src 'none'"
require_pattern "script-src 'self'"
require_pattern "form-action 'none'"
require_pattern 'max_size 6MB'
require_pattern 'respond.*200'

if rg -q 'tls[[:space:]]+internal' "$caddyfile"; then
    printf 'The public gateway must not issue a private CA certificate.\n' >&2
    exit 1
fi

if rg -q 'sapling-(output|spend)\.params|unsafe-inline.*wasm-unsafe-eval' "$caddyfile"; then
    printf 'The testnet gateway exposes an obsolete or unsafe route.\n' >&2
    exit 1
fi

printf 'Gateway checks passed.\n'
