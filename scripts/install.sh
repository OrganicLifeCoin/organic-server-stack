#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

for command_name in docker openssl; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command_name" >&2
        exit 1
    fi
done

docker compose version >/dev/null

if [[ ! -f .env ]]; then
    cp .env.example .env
    chmod 0600 .env
fi

mkdir -p .secrets
umask 077

if [[ ! -s .secrets/rpc_user ]]; then
    printf '%s\n' 'olc_stack' >.secrets/rpc_user
fi

if [[ ! -s .secrets/rpc_password ]]; then
    openssl rand -hex 32 >.secrets/rpc_password
fi

chmod 0600 .secrets/rpc_user .secrets/rpc_password

docker compose --env-file .env config --quiet
docker compose --env-file .env build
docker compose --env-file .env up -d --remove-orphans
docker compose --env-file .env ps
