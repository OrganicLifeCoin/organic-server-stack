#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
workflow="$repo_root/.github/workflows/verify.yml"

if [[ ! -f "$workflow" ]]; then
    printf 'Missing GitHub Actions workflow.\n' >&2
    exit 1
fi

required_patterns=(
    'actions/checkout@v7'
    'make check'
    'docker compose.*config'
    'caddy validate'
    'CADDY_SITE=wallet.example.com'
    'docker compose.*build'
    'Build the RPC bridge image'
    'Build the wallet image'
    'wallet-build.log'
    'Build the Blockbook image'
    'docker compose.*up.*--wait-timeout 300'
    'curl.*healthz'
    'curl.*api/v2'
    'curl.*--retry-connrefused'
    'stack-start.log'
    'docker compose.*ps --all'
    'docker inspect.*organiclife'
    'docker compose.*down'
)

for pattern in "${required_patterns[@]}"; do
    if ! rg -q -- "$pattern" "$workflow"; then
        printf 'Missing CI behavior: %s\n' "$pattern" >&2
        exit 1
    fi
done

if rg -q 'pull_request_target|permissions:[[:space:]]*write-all' "$workflow"; then
    printf 'The workflow requests an unsafe trigger or permission.\n' >&2
    exit 1
fi

printf 'CI configuration checks passed.\n'
