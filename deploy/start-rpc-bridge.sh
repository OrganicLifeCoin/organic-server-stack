#!/bin/sh
set -eu

rpc_user_file=${NODE_RPC_USER_FILE:-/run/secrets/node_rpc_user}
rpc_password_file=${NODE_RPC_PASSWORD_FILE:-/run/secrets/node_rpc_password}

if [ ! -r "$rpc_user_file" ] || [ ! -r "$rpc_password_file" ]; then
    printf 'The RPC bridge secret files are not readable.\n' >&2
    exit 1
fi

rpc_user=$(cat "$rpc_user_file")
rpc_password=$(cat "$rpc_password_file")

if [ -z "$rpc_user" ] || [ "${#rpc_password}" -lt 24 ]; then
    printf 'The RPC bridge secrets are invalid.\n' >&2
    exit 1
fi

RPC_CREDENTIALS=$rpc_user:$rpc_password
export RPC_CREDENTIALS
unset rpc_user rpc_password

exec node /app/server.js
