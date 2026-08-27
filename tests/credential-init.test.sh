#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

source_dir="$test_dir/source"
credential_dir="$test_dir/credentials"
mkdir -p "$source_dir" "$credential_dir"
printf '%s\n' 'olc_test' >"$source_dir/rpc_user"
printf '%s\n' '0123456789abcdef0123456789abcdef' >"$source_dir/rpc_password"
chmod 0600 "$source_dir/rpc_user" "$source_dir/rpc_password"

NODE_RPC_USER_FILE="$source_dir/rpc_user" \
NODE_RPC_PASSWORD_FILE="$source_dir/rpc_password" \
CREDENTIAL_DIR="$credential_dir" \
    "$repo_root/deploy/init-credentials.sh"

cmp "$source_dir/rpc_user" "$credential_dir/rpc_user"
cmp "$source_dir/rpc_password" "$credential_dir/rpc_password"

if stat -f '%Lp' "$credential_dir/rpc_user" >/dev/null 2>&1; then
    user_mode=$(stat -f '%Lp' "$credential_dir/rpc_user")
    password_mode=$(stat -f '%Lp' "$credential_dir/rpc_password")
else
    user_mode=$(stat -c '%a' "$credential_dir/rpc_user")
    password_mode=$(stat -c '%a' "$credential_dir/rpc_password")
fi

if [[ "$user_mode" != 444 || "$password_mode" != 444 ]]; then
    printf 'Initialized RPC credentials must be read-only.\n' >&2
    exit 1
fi

printf 'Credential initialization checks passed.\n'
