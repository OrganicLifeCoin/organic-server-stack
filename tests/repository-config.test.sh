#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

require_file() {
    local path=$1
    if [[ ! -f "$repo_root/$path" ]]; then
        printf 'Missing required file: %s\n' "$path" >&2
        return 1
    fi
}

require_line() {
    local path=$1
    local expected=$2
    if ! grep -Fqx "$expected" "$repo_root/$path"; then
        printf 'Missing required line in %s: %s\n' "$path" "$expected" >&2
        return 1
    fi
}

require_file .env.example
require_file .gitignore
require_file Makefile

require_line .env.example 'NETWORK=testnet'
require_line .env.example 'NODE_RELEASE=v1.1.2.0-testnet'
require_line .env.example 'WALLET_REF=ecaeb6c093a584429c94360fc69f498753d4dbe5'
require_line .env.example 'RPC_BRIDGE_REF=96074907643ae25efd043cc02ed28fd407c27882'
require_line .env.example 'BLOCKBOOK_REF=bfeb91020e9f900e316aaade639d3f021280e055'

require_line .gitignore '.env'
require_line .gitignore '.secrets/*'
require_line .gitignore '!.secrets/.gitkeep'

if ! rg -q '@set -e;.*for test_script' "$repo_root/Makefile"; then
    printf 'The Makefile can mask a failed repository check.\n' >&2
    exit 1
fi

if grep -Eiq '(password|secret|token)=[^[:space:]]+' "$repo_root/.env.example"; then
    printf 'The example environment contains a secret-like value.\n' >&2
    exit 1
fi

printf 'Repository configuration checks passed.\n'
