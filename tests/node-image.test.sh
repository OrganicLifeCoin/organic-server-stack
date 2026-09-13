#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dockerfile="$repo_root/node/Dockerfile"
entrypoint="$repo_root/node/entrypoint.sh"

for path in "$dockerfile" "$entrypoint"; do
    if [[ ! -f "$path" ]]; then
        printf 'Missing node image file: %s\n' "${path#"$repo_root/"}" >&2
        exit 1
    fi
done

require_pattern() {
    local pattern=$1
    local path=$2
    if ! rg -q -- "$pattern" "$path"; then
        printf 'Missing required pattern in %s: %s\n' "${path#"$repo_root/"}" "$pattern" >&2
        return 1
    fi
}

require_pattern 'OrganicLife-linux-\$\{release_arch\}-daemon\.zip' "$dockerfile"
require_pattern 'arm64\).*release_arch=aarch64' "$dockerfile"
require_pattern 'sha256sum --check --strict' "$dockerfile"
require_pattern 'NODE_AMD64_SHA256' "$dockerfile"
require_pattern 'NODE_ARM64_SHA256' "$dockerfile"
require_pattern 'v1\.1\.13-testnet' "$repo_root/.env.example"
require_pattern '0abc4e27dd1e744bf2306cc7fee6a05c3a95848fc6385e636a82630cee87684c' "$repo_root/.env.example"
require_pattern 'b0f3f8397bb1e471e224051a37c3272633f2b8153a58e3c799e3c30288d8b021' "$repo_root/.env.example"
require_pattern '^USER organiclife$' "$dockerfile"
require_pattern '^HEALTHCHECK ' "$dockerfile"
require_pattern 'COPY --from=fetch /release/params/' "$dockerfile"
require_pattern '^FROM debian:bookworm-slim@sha256:' "$dockerfile"

require_pattern 'NETWORK.*testnet' "$entrypoint"
require_pattern '/run/secrets/node_rpc_user' "$entrypoint"
require_pattern '/run/secrets/node_rpc_password' "$entrypoint"
require_pattern '/run/config/pq-bootstrap' "$entrypoint"
require_pattern '^pqbootstrap=\$pq_bootstrap$' "$entrypoint"
require_pattern 'chmod 0600' "$entrypoint"
require_pattern '^\[test\]$' "$entrypoint"
require_pattern 'rpcallowip=172\.29\.0\.0/24' "$entrypoint"
require_pattern '^disablewallet=1$' "$entrypoint"
require_pattern 'exec organiclifed' "$entrypoint"

test_section_line=$(rg -n '^\[test\]$' "$entrypoint" | cut -d: -f1)
for setting in 'port=' 'rpcport=' 'rpcbind='; do
    setting_line=$(rg -n "^${setting}" "$entrypoint" | cut -d: -f1)
    if [[ -z "$setting_line" || "$setting_line" -le "$test_section_line" ]]; then
        printf '%s must be defined in the testnet section.\n' "$setting" >&2
        exit 1
    fi
done

if rg -q 'curl[^\n]+\|[[:space:]]*(sh|bash)' "$dockerfile"; then
    printf 'The node image executes an unverified remote script.\n' >&2
    exit 1
fi

printf 'Node image checks passed.\n'
