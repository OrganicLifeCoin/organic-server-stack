#!/bin/sh
set -eu

umask 077

rpc_user_file=${NODE_RPC_USER_FILE:-/run/secrets/node_rpc_user}
rpc_password_file=${NODE_RPC_PASSWORD_FILE:-/run/secrets/node_rpc_password}
credential_dir=${CREDENTIAL_DIR:-/credentials}

if [ ! -r "$rpc_user_file" ] || [ ! -r "$rpc_password_file" ]; then
    printf 'The source RPC secret files are not readable.\n' >&2
    exit 1
fi

rpc_user=$(cat "$rpc_user_file")
rpc_password=$(cat "$rpc_password_file")

case "$rpc_user" in
    ''|*[!A-Za-z0-9._-]*)
        printf 'The RPC user contains an invalid character.\n' >&2
        exit 1
        ;;
esac

if [ "${#rpc_password}" -lt 24 ]; then
    printf 'The RPC password must contain at least 24 characters.\n' >&2
    exit 1
fi

single_line_password=$(printf '%s' "$rpc_password" | tr -d '\r\n')
if [ "$rpc_password" != "$single_line_password" ]; then
    printf 'The RPC password contains a line break.\n' >&2
    exit 1
fi

mkdir -p "$credential_dir"
cp "$rpc_user_file" "$credential_dir/.rpc_user.tmp"
cp "$rpc_password_file" "$credential_dir/.rpc_password.tmp"
chmod 0444 "$credential_dir/.rpc_user.tmp" "$credential_dir/.rpc_password.tmp"
mv "$credential_dir/.rpc_user.tmp" "$credential_dir/rpc_user"
mv "$credential_dir/.rpc_password.tmp" "$credential_dir/rpc_password"

unset rpc_user rpc_password single_line_password
