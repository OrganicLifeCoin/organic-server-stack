#!/bin/sh
set -eu

rpc_user_file=${NODE_RPC_USER_FILE:-/run/secrets/node_rpc_user}
rpc_password_file=${NODE_RPC_PASSWORD_FILE:-/run/secrets/node_rpc_password}

if [ ! -r "$rpc_user_file" ] || [ ! -r "$rpc_password_file" ]; then
    printf 'The Blockbook secret files are not readable.\n' >&2
    exit 1
fi

RPC_USER=$(cat "$rpc_user_file")
RPC_PASSWORD=$(cat "$rpc_password_file")

if [ -z "$RPC_USER" ] || [ "${#RPC_PASSWORD}" -lt 24 ]; then
    printf 'The Blockbook secrets are invalid.\n' >&2
    exit 1
fi

export RPC_USER RPC_PASSWORD

exec /usr/local/bin/render-blockchainconfig.sh "$@"
