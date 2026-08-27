#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
compose_file="$repo_root/compose.yaml"

if [[ ! -f "$compose_file" ]]; then
    printf 'Missing compose.yaml.\n' >&2
    exit 1
fi

compose_json=$(docker compose \
    --project-directory "$repo_root" \
    --env-file "$repo_root/.env.example" \
    -f "$compose_file" config --format json)

for service in credential-init node rpc-bridge blockbook wallet gateway; do
    if ! jq -e --arg service "$service" '.services[$service]' <<<"$compose_json" >/dev/null; then
        printf 'Missing service: %s\n' "$service" >&2
        exit 1
    fi
done

if jq -e '.services.node.ports // empty' <<<"$compose_json" >/dev/null; then
    printf 'The node must not publish a host port.\n' >&2
    exit 1
fi

for service in rpc-bridge blockbook wallet; do
    if jq -e --arg service "$service" '.services[$service].ports // empty' <<<"$compose_json" >/dev/null; then
        printf '%s must not publish a host port.\n' "$service" >&2
        exit 1
    fi
done

if [[ $(jq '.services.gateway.ports | length' <<<"$compose_json") -ne 2 ]]; then
    printf 'The gateway must publish HTTP and HTTPS only.\n' >&2
    exit 1
fi

if ! jq -e '.services.gateway.healthcheck.test | join(" ") | contains("127.0.0.1:8081/healthz")' \
    <<<"$compose_json" >/dev/null; then
    printf 'The gateway health check is not independent from the public hostname.\n' >&2
    exit 1
fi

for secret in node_rpc_user node_rpc_password; do
    if ! jq -e --arg secret "$secret" \
        '.services["credential-init"].secrets[] | select(.source == $secret)' \
        <<<"$compose_json" >/dev/null; then
        printf 'credential-init does not receive %s.\n' "$secret" >&2
        exit 1
    fi
done

for service in node rpc-bridge blockbook; do
    if jq -e --arg service "$service" '.services[$service].secrets // empty' \
        <<<"$compose_json" >/dev/null; then
        printf '%s must consume the private credential volume, not host secret mounts.\n' "$service" >&2
        exit 1
    fi

    if ! jq -e --arg service "$service" \
        '.services[$service].volumes[] | select(.source == "rpc-credentials" and .target == "/run/credentials" and .read_only == true)' \
        <<<"$compose_json" >/dev/null; then
        printf '%s does not receive the read-only credential volume.\n' "$service" >&2
        exit 1
    fi

    if ! jq -e --arg service "$service" \
        '.services[$service].depends_on["credential-init"].condition == "service_completed_successfully"' \
        <<<"$compose_json" >/dev/null; then
        printf '%s does not wait for credential initialization.\n' "$service" >&2
        exit 1
    fi
done

for service in credential-init node rpc-bridge blockbook wallet; do
    if ! jq -e --arg service "$service" \
        '.services[$service].security_opt | index("no-new-privileges:true")' \
        <<<"$compose_json" >/dev/null; then
        printf '%s does not disable privilege escalation.\n' "$service" >&2
        exit 1
    fi
done

for capability in CHOWN SETGID SETUID NET_BIND_SERVICE; do
    if ! jq -e --arg capability "$capability" \
        '.services.wallet.cap_add | index($capability)' <<<"$compose_json" >/dev/null; then
        printf 'The wallet lacks its required Nginx capability: %s\n' "$capability" >&2
        exit 1
    fi
done

if rg -n '(#main|:latest|refs/heads/main)' "$compose_file"; then
    printf 'Mutable component reference found.\n' >&2
    exit 1
fi

if ! rg -q 'caddy:2\.11\.4-alpine@sha256:' "$compose_file"; then
    printf 'The gateway image is not pinned by digest.\n' >&2
    exit 1
fi

if ! rg -q 'alpine:3\.22\.1@sha256:' "$compose_file"; then
    printf 'The credential initializer image is not pinned by digest.\n' >&2
    exit 1
fi

if ! jq -e '.networks.backend.ipam.config[0].subnet == "172.29.0.0/24"' \
    <<<"$compose_json" >/dev/null; then
    printf 'The private RPC subnet does not match the node allow list.\n' >&2
    exit 1
fi

printf 'Compose checks passed.\n'
