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
require_line .env.example 'NODE_RELEASE=v1.1.13-testnet'
require_line .env.example 'WALLET_REF=8a310ef3304c67f70e6fe7255447140c36c2d0ad'
require_line .env.example 'RPC_BRIDGE_REF=545612e1b9ffb1e536cfc004900a91f814b3caed'
require_line .env.example 'BLOCKBOOK_REF=1af4295e2f10c66cf0e51b0ef21f70a7203b98a1'

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
